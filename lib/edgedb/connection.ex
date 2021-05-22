defmodule EdgeDB.Connection do
  use DBConnection

  use EdgeDB.Protocol.Messages

  alias EdgeDB.Connection.QueriesCache

  alias EdgeDB.Protocol.{
    Codecs,
    Errors
  }

  require Logger

  @default_hostname "127.0.0.1"
  @default_port 5656
  @default_username "edgedb"
  @default_database "edgedb"

  @default_timeout 15_000
  @max_packet_size 64 * 1024 * 1024
  @tcp_socket_opts [packet: :raw, mode: :binary, active: false]

  @scram_sha_256 "SCRAM-SHA-256"

  @start_transaction_statement "START TRANSACTION"
  @commit_statement "COMMIT"
  @rollback_statement "ROLLBACK"

  defmodule State do
    defstruct socket: nil,
              username: nil,
              database: nil,
              buffer: <<>>,
              server_key_data: nil,
              server_state: nil,
              codecs_storage: nil,
              queries_cache: nil
  end

  @impl DBConnection
  def checkin(state) do
    {:ok, state}
  end

  @impl DBConnection
  def checkout(state) do
    {:ok, state}
  end

  @impl DBConnection
  def connect(opts \\ []) do
    host = Keyword.get(opts, :host, @default_hostname)
    port = Keyword.get(opts, :port, @default_port)
    username = Keyword.get(opts, :username, @default_username)
    database = Keyword.get(opts, :database, @default_database)
    password = Keyword.get(opts, :password)

    {:ok, qc} = QueriesCache.start_link()
    {:ok, cs} = Codecs.Storage.start_link()

    state = %State{
      codecs_storage: cs,
      queries_cache: qc
    }

    with {:ok, state} <- open_tcp_connection(host, port, state),
         {:ok, state} <- handshake(state, username, password, database),
         {:ok, state} <- wait_for_server_ready(state) do
      {:ok, state}
    else
      {:disconnect, err, state} ->
        disconnect(err, state)
        {:error, err}
    end
  end

  @impl DBConnection
  def disconnect(_err, %State{socket: socket} = state) do
    with :ok <- send_message(state, terminate()) do
      :gen_tcp.close(socket)
    end
  end

  @impl DBConnection

  def handle_begin(_opts, %State{server_state: server_state} = state)
      when server_state in [:in_transaction, :in_failed_transaction] do
    {status(server_state), state}
  end

  def handle_begin(opts, %State{} = state) do
    start_transaction(opts, state)
  end

  @impl DBConnection
  def handle_close(
        %EdgeDB.Query{input_codec: in_codec, output_codec: out_codec} = query,
        _opts,
        state
      )
      when not is_nil(in_codec) and not is_nil(out_codec) do
    close_prepared_query(query, state)
  end

  @impl DBConnection

  def handle_commit(_opts, %State{server_state: server_state} = state)
      when server_state in [:not_in_transaction, :in_failed_transaction] do
    {status(server_state), state}
  end

  def handle_commit(_opts, state) do
    commit_transaction(state)
  end

  @impl DBConnection
  def handle_deallocate(_query, _cursor, _opts, state) do
    {:disconnect, {:not_implemented, :handle_deallocate}, state}
  end

  @impl DBConnection
  def handle_declare(_query, _params, _opts, state) do
    {:disconnect, {:not_implemented, :handle_declare}, state}
  end

  @impl DBConnection

  def handle_execute(%EdgeDB.Query{cached?: true} = query, params, opts, state) do
    optimistic_execute_query(query, params, opts, state)
  end

  def handle_execute(%EdgeDB.Query{} = query, params, _opts, state) do
    execute_query(query, params, state)
  end

  @impl DBConnection
  def handle_fetch(_query, _cursor, _opts, state) do
    {:disconnect, {:not_implemented, :handle_fetch}, state}
  end

  @impl DBConnection
  def handle_prepare(%EdgeDB.Query{} = query, opts, %State{queries_cache: qc} = state) do
    case QueriesCache.get(qc, query.statement, query.cardinality, query.io_format) do
      %EdgeDB.Query{cached?: true} = cached_query ->
        {:ok, cached_query, state}

      nil ->
        prepare_query(query, opts, state)
    end
  end

  @impl DBConnection

  def handle_rollback(_opts, %State{server_state: server_state} = state)
      when server_state == :not_in_transaction do
    {server_state, state}
  end

  def handle_rollback(_opts, state) do
    rollback_transaction(state)
  end

  @impl DBConnection
  def handle_status(_opts, state) do
    {status(state), state}
  end

  @impl DBConnection
  def ping(state) do
    {:ok, state}
  end

  defp open_tcp_connection(host, port, %State{} = state) do
    with {:ok, socket} <-
           :gen_tcp.connect(to_charlist(host), port, @tcp_socket_opts, @default_timeout) do
      {:ok, %State{state | socket: socket}}
    end
  end

  defp handshake(%State{} = state, username, password, database) do
    message =
      client_handshake(
        params: [
          connection_param(name: "user", value: username),
          connection_param(name: "database", value: database)
        ],
        extensions: []
      )

    with :ok <- send_message(state, message) do
      handle_authentication(%State{state | username: username, database: database}, password)
    end
  end

  defp handle_authentication(state, password) do
    with {:ok, {message, buffer}} <- receive_message(state) do
      handle_authentication_flow(message, password, %State{state | buffer: buffer})
    end
  end

  defp handle_authentication_flow(server_handshake(), password, state) do
    with {:ok, {message, buffer}} <- receive_message(state) do
      handle_authentication_flow(message, password, %State{state | buffer: buffer})
    end
  end

  defp handle_authentication_flow(authentication_ok(), _password, state) do
    {:ok, state}
  end

  defp handle_authentication_flow(authentication_sasl(), nil, %State{} = state) do
    err =
      Errors.AuthenticationError.exception(
        "password should be provided for #{inspect(state.username)} authentication authentication"
      )

    {:disconnect, err, state}
  end

  defp handle_authentication_flow(
         authentication_sasl(methods: [@scram_sha_256]),
         password,
         %State{} = state
       ) do
    {server_first, cf_data} = EdgeDB.SCRAM.handle_client_first(state.username, password)

    message = authentication_sasl_initial_response(method: @scram_sha_256, sasl_data: cf_data)

    with :ok <- send_message(state, message),
         {:ok, {message, buffer}} <- receive_message(state) do
      handle_sasl_authentication_flow(message, server_first, %State{state | buffer: buffer})
    end
  end

  defp handle_authentication_flow(error_response() = message, _password, state) do
    handle_error_response(message, state)
  end

  defp handle_sasl_authentication_flow(
         authentication_sasl_continue(sasl_data: data),
         server_first,
         state
       ) do
    with {:ok, {server_final, client_final_data}} <-
           EdgeDB.SCRAM.handle_server_first(server_first, data),
         :ok <- send_message(state, authentication_sasl_response(sasl_data: client_final_data)),
         {:ok, {message, buffer}} <- receive_message(state) do
      handle_sasl_authentication_flow(message, server_final, %State{state | buffer: buffer})
    end
  end

  defp handle_sasl_authentication_flow(
         authentication_sasl_final(sasl_data: data),
         server_final,
         state
       ) do
    with :ok <- EdgeDB.SCRAM.handle_server_final(server_final, data),
         {:ok, {message, buffer}} <- receive_message(state) do
      handle_sasl_authentication_flow(message, %State{state | buffer: buffer})
    end
  end

  defp handle_sasl_authentication_flow(error_response() = message, _scram_data, state) do
    handle_error_response(message, state)
  end

  defp handle_sasl_authentication_flow(authentication_ok(), state) do
    {:ok, state}
  end

  defp handle_sasl_authentication_flow(error_response() = message, state) do
    handle_error_response(message, state)
  end

  defp wait_for_server_ready(state) do
    with {:ok, {message, buffer}} <- receive_message(state) do
      handle_server_ready_flow(message, %State{state | buffer: buffer})
    end
  end

  defp handle_server_ready_flow(server_key_data(data: data), state) do
    wait_for_server_ready(%State{state | server_key_data: data})
  end

  # TODO: maybe use it somehow, but right now just ignore it
  defp handle_server_ready_flow(parameter_status(), state) do
    wait_for_server_ready(state)
  end

  defp handle_server_ready_flow(ready_for_command(transaction_state: transaction_state), state) do
    {:ok, %State{state | server_state: transaction_state}}
  end

  defp handle_server_ready_flow(error_response() = message, state) do
    handle_error_response(message, state)
  end

  defp prepare_query(%EdgeDB.Query{} = query, opts, state) do
    message =
      prepare(
        headers: opts,
        io_format: query.io_format,
        expected_cardinality: query.cardinality,
        command: query.statement
      )

    with :ok <- send_messages(state, [message, flush()]),
         {:ok, {message, buffer}} <- receive_message(state) do
      handle_prepare_query_flow(query, message, %State{state | buffer: buffer})
    end
  end

  defp handle_prepare_query_flow(
         %EdgeDB.Query{cardinality: :one},
         prepare_complete(cardinality: :no_result),
         state
       ) do
    exc =
      Errors.CardinalityViolationError.exception(
        "cann't execute query since expected single result and query doesn't return any data"
      )

    {:disconnect, exc, state}
  end

  defp handle_prepare_query_flow(
         query,
         prepare_complete(
           input_typedesc_id: in_id,
           output_typedesc_id: out_id
         ),
         %State{queries_cache: qc, codecs_storage: cs} = state
       ) do
    input_codec = Codecs.Storage.get(cs, in_id)
    output_codec = Codecs.Storage.get(cs, out_id)

    if is_nil(input_codec) or is_nil(output_codec) do
      describe_codecs_from_query(query, state)
    else
      query = save_query_with_codecs_in_cache(qc, query, input_codec, output_codec)

      {:ok, query, state}
    end
  end

  defp handle_prepare_query_flow(
         %EdgeDB.Query{cardinality: :one},
         command_data_description(result_cardinality: :no_result),
         state
       ) do
    exc =
      Errors.CardinalityViolationError.exception(
        "cann't execute query since expected single result and query doesn't return any data"
      )

    {:disconnect, exc, state}
  end

  defp handle_prepare_query_flow(
         query,
         command_data_description() = message,
         %State{codecs_storage: cs, queries_cache: qc} = state
       ) do
    {input_codec, output_codec} = parse_description_message(message, cs)

    query = save_query_with_codecs_in_cache(qc, query, input_codec, output_codec)

    {:ok, query, state}
  end

  defp handle_prepare_query_flow(_query, error_response() = message, state) do
    handle_error_response(message, state)
  end

  defp optimistic_execute_query(%EdgeDB.Query{} = query, params, opts, state) do
    message =
      optimistic_execute(
        headers: opts,
        io_format: query.io_format,
        expected_cardinality: query.cardinality,
        command_text: query.statement,
        input_typedesc_id: query.input_codec.type_id,
        output_typedesc_id: query.output_codec.type_id,
        arguments: params
      )

    with :ok <- send_messages(state, [message, sync()]),
         {:ok, {message, buffer}} <- receive_message(state) do
      handle_optimistic_execute_flow(
        query,
        EdgeDB.Result.new(query.cardinality),
        message,
        %State{state | buffer: buffer}
      )
    end
  end

  defp handle_optimistic_execute_flow(
         %EdgeDB.Query{cardinality: :one},
         _result,
         command_data_description(result_cardinality: :no_result),
         state
       ) do
    exc =
      Errors.CardinalityViolationError.exception(
        "cann't execute query since expected single result and query doesn't return any data"
      )

    {:disconnect, exc, state}
  end

  defp handle_optimistic_execute_flow(
         query,
         _result,
         command_data_description() = message,
         %State{codecs_storage: cs, queries_cache: qc} = state
       ) do
    {input_codec, output_codec} = parse_description_message(message, cs)
    query = save_query_with_codecs_in_cache(qc, query, input_codec, output_codec)
    reencoded_params = DBConnection.Query.encode(query, query.params, [])
    execute_query(query, reencoded_params, state)
  end

  defp handle_optimistic_execute_flow(query, result, data() = message, state) do
    handle_execute_flow(query, result, message, state)
  end

  defp handle_optimistic_execute_flow(_query, _result, error_response() = message, state) do
    handle_error_response(message, state)
  end

  defp execute_query(%EdgeDB.Query{} = query, params, state) do
    message = execute(arguments: params)

    with :ok <- send_messages(state, [message, sync()]),
         {:ok, {message, buffer}} <- receive_message(state) do
      handle_execute_flow(
        query,
        EdgeDB.Result.new(query.cardinality),
        message,
        %State{state | buffer: buffer}
      )
    end
  end

  defp handle_execute_flow(
         %EdgeDB.Query{} = query,
         result,
         data(data: [data_element(data: data)]),
         state
       ) do
    result = EdgeDB.Result.add_encoded_data(result, data)

    with {:ok, {message, buffer}} <- receive_message(state) do
      handle_execute_flow(query, result, message, %State{state | buffer: buffer})
    end
  end

  defp handle_execute_flow(query, result, command_complete(status: status), state) do
    with {:ok, state} <- wait_for_server_ready(state) do
      {:ok, query, %EdgeDB.Result{result | statement: status}, state}
    end
  end

  defp handle_execute_flow(_query, _result, error_response() = message, state) do
    handle_error_response(message, state)
  end

  defp describe_codecs_from_query(query, state) do
    message = describe_statement(aspect: :data_description)

    with :ok <- send_messages(state, [message, flush()]),
         {:ok, {message, buffer}} <- receive_message(state) do
      handle_prepare_query_flow(query, message, %State{state | buffer: buffer})
    end
  end

  defp parse_description_message(
         command_data_description(
           input_typedesc_id: input_typedesc_id,
           input_typedesc: input_typedesc,
           output_typedesc_id: output_typedesc_id,
           output_typedesc: output_typedesc
         ),
         codecs_storage
       ) do
    input_codec =
      Codecs.Storage.get_or_create(codecs_storage, input_typedesc_id, fn ->
        Codecs.from_type_description(codecs_storage, input_typedesc)
      end)

    output_codec =
      Codecs.Storage.get_or_create(codecs_storage, output_typedesc_id, fn ->
        Codecs.from_type_description(codecs_storage, output_typedesc)
      end)

    {input_codec, output_codec}
  end

  defp close_prepared_query(query, %State{} = state) do
    QueriesCache.clear(state.queries_cache, query)
    {:ok, EdgeDB.Result.query_closed(), state}
  end

  defp start_transaction(opts, state) do
    transaction_statement = create_start_transaction_statement(opts)

    execute_script(
      transaction_statement,
      [allow_capabilities: :all],
      state
    )
  end

  defp commit_transaction(state) do
    execute_script(@commit_statement, [allow_capabilities: :all], state)
  end

  defp rollback_transaction(state) do
    execute_script(@rollback_statement, [allow_capabilities: :all], state)
  end

  defp execute_script(statement, headers, state) do
    message =
      execute_script(
        headers: headers,
        script: statement
      )

    with :ok <- send_message(state, message),
         {:ok, {message, buffer}} <- receive_message(state) do
      handle_execute_script_flow(message, %State{state | buffer: buffer})
    end
  end

  defp handle_execute_script_flow(command_complete(status: status), state) do
    result = %EdgeDB.Result{
      cardinality: :no_result,
      statement: status
    }

    with {:ok, state} <- wait_for_server_ready(state) do
      {:ok, result, state}
    end
  end

  defp handle_execute_script_flow(error_response() = message, state) do
    handle_error_response(message, state)
  end

  defp handle_error_response(
         error_response(
           error_code: code,
           message: message,
           attributes: attributes
         ),
         state
       ) do
    err = Errors.module_from_code(code).exception(message, meta: Enum.into(attributes, %{}))
    {:disconnect, err, state}
  end

  defp handle_log_message(log_message(severity: severity, text: text), state) do
    Logger.log(severity, text)
    state
  end

  defp save_query_with_codecs_in_cache(
         queries_cache,
         query,
         input_codec,
         output_codec
       ) do
    query = %EdgeDB.Query{
      query
      | input_codec: input_codec,
        output_codec: output_codec
    }

    QueriesCache.add(queries_cache, query)

    query
  end

  defp send_message(state, message) do
    :gen_tcp.send(state.socket, EdgeDB.Protocol.encode(message))
  end

  defp send_messages(state, messages) when is_list(messages) do
    encoded_messages =
      Enum.map(messages, fn message ->
        EdgeDB.Protocol.encode(message)
      end)

    :gen_tcp.send(state.socket, encoded_messages)
  end

  defp receive_message(state) do
    case EdgeDB.Protocol.decode(state.buffer) do
      {:ok, {log_message() = message, buffer}} ->
        state = handle_log_message(message, %State{state | buffer: buffer})
        receive_message(state)

      {:ok, _res} = result ->
        result

      {:error, {:not_enough_size, size}} ->
        receive_message_data_from_socket(state, size)
    end
  end

  defp receive_message_data_from_socket(state, required_data_size) do
    with {:ok, data} <-
           :gen_tcp.recv(
             state.socket,
             min(required_data_size, @max_packet_size),
             @default_timeout
           ) do
      receive_message(%State{state | buffer: state.buffer <> data})
    end
  end

  defp status(%State{server_state: :not_in_transaction}) do
    :idle
  end

  defp status(%State{server_state: :in_transaction}) do
    :transaction
  end

  defp status(%State{server_state: :in_failed_transaction}) do
    :error
  end

  defp create_start_transaction_statement(opts) do
    isolation =
      case Keyword.get(opts, :isolation, :repeatable_read) do
        :serializable ->
          "ISOLATION SERIALIZABLE"

        :repeatable_read ->
          "ISOLATION REPEATABLE READ"
      end

    read =
      if Keyword.get(opts, :readonly, false) do
        "READ ONLY"
      end

    deferrable =
      case Keyword.get(opts, :deferrable) do
        true ->
          "DEFERRABLE"

        false ->
          "NOT DEFERRABLE"

        nil ->
          ""
      end

    "#{@start_transaction_statement} #{isolation} #{read} #{deferrable}"
  end
end
