defmodule EdgeDB.Connection do
  @moduledoc false

  use DBConnection

  use EdgeDB.Protocol

  alias EdgeDB.Connection.{
    InternalRequest,
    QueriesCache,
    QueryBuilder,
    State
  }

  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    Enums
  }

  alias EdgeDB.SCRAM

  require Logger

  @max_packet_size 64 * 1024 * 1024
  @tcp_socket_opts [packet: :raw, mode: :binary, active: false]
  @ssl_socket_opts []

  @scram_sha_256 "SCRAM-SHA-256"
  @major_ver 0
  @minor_ver 13
  @minor_ver_min 13
  @edgedb_alpn_protocol "edgedb-binary"

  defmodule State do
    @moduledoc false

    defstruct [
      :socket,
      :user,
      :database,
      :queries_cache,
      :codecs_storage,
      :timeout,
      capabilities: [],
      transaction_options: [],
      retry_options: [],
      buffer: <<>>,
      server_key_data: nil,
      server_state: :not_in_transaction,
      server_settings: %{},
      ping_interval: nil,
      last_active: nil,
      savepoint_id: 0
    ]

    @type t() :: %__MODULE__{
            socket: :ssl.sslsocket(),
            user: String.t(),
            database: String.t(),
            timeout: timeout(),
            capabilities: Enums.Capabilities.t(),
            transaction_options: list(EdgeDB.edgedb_transaction_option()),
            retry_options: list(EdgeDB.retry_option()),
            buffer: bitstring(),
            server_key_data: list(byte()) | nil,
            server_state: Enums.TransactionState.t(),
            queries_cache: QueriesCache.t(),
            codecs_storage: Codecs.Storage.t(),
            server_settings: map(),
            ping_interval: integer() | nil | :disabled,
            last_active: integer() | nil,
            savepoint_id: integer()
          }
  end

  @impl DBConnection
  def checkout(state) do
    {:ok, state}
  end

  @impl DBConnection
  def connect(opts \\ []) do
    {host, port} = opts[:address]
    user = opts[:user]
    password = opts[:password]
    database = opts[:database]
    codecs_modules = opts[:codecs] || []
    transaction_opts = opts[:transaction] || []
    retry_opts = opts[:retry] || []

    tcp_opts = (opts[:tcp] || []) ++ @tcp_socket_opts

    ssl_opts =
      @ssl_socket_opts
      |> Keyword.merge(opts[:ssl] || [])
      |> add_custom_edgedb_ssl_opts(opts)

    timeout = opts[:timeout]

    state = %State{
      user: user,
      database: database,
      timeout: timeout,
      transaction_options: transaction_opts,
      retry_options: retry_opts
    }

    with {:ok, qc} <- QueriesCache.start_link(),
         {:ok, cs} <- Codecs.Storage.start_link(),
         {:ok, socket} <- open_ssl_connection(host, port, tcp_opts, ssl_opts, timeout),
         state = %State{state | socket: socket, queries_cache: qc, codecs_storage: cs},
         {:ok, state} <- handshake(password, state),
         {:ok, state} <- wait_for_server_ready(state),
         {:ok, state} <- initialize_custom_codecs(codecs_modules, state) do
      {:ok, state}
    else
      {:error, reason} ->
        exc =
          EdgeDB.Error.client_connection_error(
            "unable to establish connection: #{inspect(reason)}"
          )

        {:error, exc}

      {:error, exc, state} ->
        disconnect(exc, state)
        {:error, exc}

      {:disconnect, exc, state} ->
        disconnect(exc, state)
        {:error, exc}
    end
  end

  @impl DBConnection
  def disconnect(
        %EdgeDB.Error{name: "ClientConnectionClosedError"},
        %State{socket: socket}
      ) do
    :ssl.close(socket)
  end

  @impl DBConnection
  def disconnect(_exc, %State{socket: socket} = state) do
    with {:ok, _state} <- send_message(%Terminate{}, state) do
      :ssl.close(socket)
    end
  end

  @impl DBConnection
  def handle_begin(_opts, %State{server_state: server_state} = state)
      when server_state in [:in_transaction, :in_failed_transaction] do
    {status(state), state}
  end

  @impl DBConnection
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
    {status(state), state}
  end

  @impl DBConnection
  def handle_commit(_opts, state) do
    commit_transaction(state)
  end

  @impl DBConnection
  def handle_deallocate(_query, _cursor, _opts, state) do
    exc = EdgeDB.Error.interface_error("handle_deallocate/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_declare(_query, _params, _opts, state) do
    exc = EdgeDB.Error.interface_error("handle_declare/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_execute(%EdgeDB.Query{cached: true} = query, params, opts, state) do
    case optimistic_execute_query(query, params, opts, state) do
      {:ok, query, result, state} ->
        {:ok, query, result, state}

      {reason, %EdgeDB.Error{query: nil} = exc, state} ->
        {reason, %EdgeDB.Error{exc | query: query}, state}

      {reason, exc, state} ->
        {reason, exc, state}
    end
  end

  @impl DBConnection
  def handle_execute(%EdgeDB.Query{} = query, params, opts, state) do
    case execute_query(query, params, opts, state) do
      {:ok, query, result, state} ->
        {:ok, query, result, state}

      {reason, %EdgeDB.Error{query: nil} = exc, state} ->
        {reason, %EdgeDB.Error{exc | query: query}, state}

      {reason, exc, state} ->
        {reason, exc, state}
    end
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :capabilities} = request,
        _params,
        _opts,
        %State{} = state
      ) do
    {:ok, request, state.capabilities, state}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :set_capabilities} = request,
        %{capabilities: capabilities},
        _opts,
        %State{} = state
      ) do
    {:ok, request, :ok, %State{state | capabilities: capabilities}}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :transaction_options} = request,
        _params,
        _opts,
        %State{} = state
      ) do
    {:ok, request, state.transaction_options, state}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :set_transaction_options} = request,
        %{options: opts},
        _opts,
        %State{} = state
      ) do
    {:ok, request, :ok, %State{state | transaction_options: opts}}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :retry_options} = request,
        _params,
        _opts,
        %State{} = state
      ) do
    {:ok, request, state.retry_options, state}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :set_retry_options} = request,
        %{options: retry_opts},
        opts,
        %State{} = state
      ) do
    retry_opts =
      if opts[:replace] do
        retry_opts
      else
        Keyword.merge(state.retry_options, retry_opts)
      end

    {:ok, request, :ok, %State{state | retry_options: retry_opts}}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :execute_granular_flow},
        %{query: %EdgeDB.Query{} = query, params: params},
        opts,
        %State{} = state
      ) do
    handle_execute(query, params, opts, state)
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :execute_script_flow} = request,
        %{statement: statement, headers: headers},
        _opts,
        %State{} = state
      ) do
    case execute_script_query(statement, headers, state) do
      {:ok, result, state} ->
        {:ok, request, result, state}

      other ->
        other
    end
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :next_savepoint} = request,
        _params,
        _opts,
        %State{savepoint_id: savepoint_id} = state
      ) do
    next_savepoint = savepoint_id + 1
    {:ok, request, next_savepoint, %State{state | savepoint_id: next_savepoint}}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :is_subtransaction} = request,
        _params,
        _opts,
        %State{} = state
      ) do
    {:ok, request, false, state}
  end

  @impl DBConnection
  def handle_execute(%InternalRequest{request: request}, _params, _opts, state) do
    exc =
      EdgeDB.Error.interface_error("unknown internal request to connection: #{inspect(request)}")

    {:error, exc, state}
  end

  @impl DBConnection
  def handle_fetch(_query, _cursor, _opts, state) do
    exc = EdgeDB.Error.interface_error("handle_fetch/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_prepare(%EdgeDB.Query{} = query, opts, %State{queries_cache: qc} = state) do
    case QueriesCache.get(qc, query.statement, query.cardinality, query.io_format, query.required) do
      %EdgeDB.Query{} = cached_query ->
        {:ok, cached_query, state}

      nil ->
        prepare_query(query, opts, state)
    end
  end

  @impl DBConnection
  def handle_rollback(_opts, %State{server_state: server_state} = state)
      when server_state == :not_in_transaction do
    {status(state), state}
  end

  @impl DBConnection
  def handle_rollback(_opts, state) do
    rollback_transaction(state)
  end

  @impl DBConnection
  def handle_status(_opts, state) do
    {status(state), state}
  end

  # "Real" pings are performed according to the EdgeDB system configuration "session_idle_timeout" parameter,
  # but by default this callback won't be called more than once per second.
  # If "session_idle_timeout" parameter is disabled, pings will also be disabled.
  @impl DBConnection
  def ping(state) do
    maybe_ping(state)
  end

  defp open_ssl_connection(host, port, tcp_opts, ssl_opts, timeout) do
    host = to_charlist(host)

    with {:ok, socket} <- :gen_tcp.connect(host, port, tcp_opts, timeout),
         {:ok, socket} <- :ssl.connect(socket, ssl_opts, timeout),
         {:ok, @edgedb_alpn_protocol} <- :ssl.negotiated_protocol(socket) do
      {:ok, socket}
    end
  end

  defp add_custom_edgedb_ssl_opts(socket_opts, connect_opts) do
    socket_opts =
      case connect_opts[:tls_ca] do
        nil ->
          socket_opts

        pem_cert_data ->
          {:Certificate, der_cert_data, _cipher_info} =
            pem_cert_data
            |> :public_key.pem_decode()
            |> Enum.find(fn
              {:Certificate, _der_cert_data, _cipher_info} ->
                true

              _other ->
                false
            end)

          Keyword.put(socket_opts, :cacerts, [der_cert_data])
      end

    socket_opts =
      case connect_opts[:tls_security] do
        :strict ->
          Keyword.put(socket_opts, :verify, :verify_peer)

        :no_host_verification ->
          socket_opts

        :insecure ->
          Keyword.put(socket_opts, :verify, :verify_none)
      end

    Keyword.put(socket_opts, :alpn_advertised_protocols, [@edgedb_alpn_protocol])
  end

  defp handshake(password, %State{} = state) do
    message = %ClientHandshake{
      major_ver: @major_ver,
      minor_ver: @minor_ver,
      params: [
        %ConnectionParam{
          name: "user",
          value: state.user
        },
        %ConnectionParam{
          name: "database",
          value: state.database
        }
      ],
      extensions: []
    }

    with {:ok, state} <- send_message(message, state) do
      handle_authentication(password, state)
    end
  end

  defp handle_authentication(password, state) do
    with {:ok, {message, state}} <- receive_message(state) do
      handle_authentication_flow(message, password, state)
    end
  end

  defp handle_authentication_flow(
         %ServerHandshake{major_ver: major_ver, minor_ver: minor_ver},
         _password,
         state
       )
       when major_ver != @major_ver or
              (major_ver == 0 and (minor_ver < @minor_ver_min or minor_ver > @minor_ver)) do
    exc =
      EdgeDB.Error.client_connection_error(
        "the server requested an unsupported version of the protocol #{major_ver}.#{minor_ver}"
      )

    {:disconnect, exc, state}
  end

  defp handle_authentication_flow(
         %ServerHandshake{},
         password,
         state
       ) do
    with {:ok, {message, state}} <- receive_message(state) do
      handle_authentication_flow(message, password, state)
    end
  end

  defp handle_authentication_flow(%AuthenticationOK{}, _password, state) do
    {:ok, state}
  end

  defp handle_authentication_flow(%AuthenticationSASL{}, nil, %State{} = state) do
    exc =
      EdgeDB.Error.authentication_error(
        "password should be provided for #{inspect(state.user)} authentication authentication"
      )

    {:disconnect, exc, state}
  end

  defp handle_authentication_flow(
         %AuthenticationSASL{methods: [@scram_sha_256]},
         password,
         %State{} = state
       ) do
    {server_first, cf_data} = EdgeDB.SCRAM.handle_client_first(state.user, password)

    message = %AuthenticationSASLInitialResponse{
      method: @scram_sha_256,
      sasl_data: cf_data
    }

    with {:ok, state} <- send_message(message, state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_sasl_authentication_flow(message, server_first, state)
    end
  end

  defp handle_authentication_flow(%ErrorResponse{} = message, _password, state) do
    handle_error_response(message, state)
  end

  defp handle_sasl_authentication_flow(
         %AuthenticationSASLContinue{sasl_data: data},
         %SCRAM.ServerFirst{} = server_first,
         state
       ) do
    with {:ok, {server_final, client_final_data}} <-
           EdgeDB.SCRAM.handle_server_first(server_first, data),
         {:ok, state} <-
           send_message(%AuthenticationSASLResponse{sasl_data: client_final_data}, state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_sasl_authentication_flow(message, server_final, state)
    else
      {:error, reason} ->
        exc =
          EdgeDB.Error.authentication_error(
            "unable to continue SASL authentication: #{inspect(reason)}"
          )

        {:disconnect, exc, state}

      {:disconnect, _exc, _state} = disconnect ->
        disconnect
    end
  end

  defp handle_sasl_authentication_flow(
         %AuthenticationSASLFinal{sasl_data: data},
         %SCRAM.ServerFinal{} = server_final,
         state
       ) do
    with :ok <- EdgeDB.SCRAM.handle_server_final(server_final, data),
         {:ok, {message, state}} <- receive_message(state) do
      handle_sasl_authentication_flow(message, state)
    else
      {:error, reason} ->
        exc =
          EdgeDB.Error.authentication_error(
            "unable to complete SASL authentication: #{inspect(reason)}"
          )

        {:disconnect, exc, state}

      {:disconnect, _exc, _state} = disconnect ->
        disconnect
    end
  end

  defp handle_sasl_authentication_flow(%ErrorResponse{} = message, _scram_data, state) do
    handle_error_response(message, state)
  end

  defp handle_sasl_authentication_flow(%AuthenticationOK{}, state) do
    {:ok, state}
  end

  defp handle_sasl_authentication_flow(%ErrorResponse{} = message, state) do
    handle_error_response(message, state)
  end

  defp wait_for_server_ready(state) do
    with {:ok, {message, state}} <- receive_message(state) do
      handle_server_ready_flow(message, state)
    end
  end

  defp handle_server_ready_flow(%ServerKeyData{data: data}, state) do
    wait_for_server_ready(%State{state | server_key_data: data})
  end

  # TODO: maybe use it somehow, but right now just ignore it
  defp handle_server_ready_flow(
         %ParameterStatus{name: "suggested_pool_concurrency", value: value},
         state
       ) do
    {pool_concurrency, ""} = Integer.parse(value)

    wait_for_server_ready(%State{
      state
      | server_settings:
          Map.put(
            state.server_settings,
            :pool_concurrency,
            pool_concurrency
          )
    })
  end

  defp handle_server_ready_flow(%ParameterStatus{name: "system_config", value: value}, state) do
    wait_for_server_ready(%State{
      state
      | server_settings:
          Map.put(
            state.server_settings,
            :system_config,
            parse_system_config(value, state)
          )
    })
  end

  defp handle_server_ready_flow(%ParameterStatus{}, state) do
    wait_for_server_ready(state)
  end

  defp handle_server_ready_flow(%ReadyForCommand{transaction_state: transaction_state}, state) do
    {:ok, %State{state | server_state: transaction_state}}
  end

  defp handle_server_ready_flow(%ErrorResponse{} = message, state) do
    handle_error_response(message, state)
  end

  defp prepare_query(%EdgeDB.Query{} = query, opts, state) do
    message = %Prepare{
      headers: prepare_headers(opts, state),
      io_format: query.io_format,
      expected_cardinality: query.cardinality,
      command: query.statement
    }

    with {:ok, state} <- send_messages([message, %Sync{}], state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_prepare_query_flow(query, message, state)
    end
  end

  defp handle_prepare_query_flow(
         %EdgeDB.Query{cardinality: :one} = query,
         %PrepareComplete{cardinality: :no_result, headers: %{capabilities: capabilities}},
         state
       ) do
    exc =
      EdgeDB.Error.cardinality_violation_error(
        "can't execute query since expected single result and query doesn't return any data",
        query: %EdgeDB.Query{query | capabilities: capabilities}
      )

    with {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp handle_prepare_query_flow(
         query,
         %PrepareComplete{
           input_typedesc_id: in_id,
           output_typedesc_id: out_id,
           headers: %{capabilities: capabilities}
         },
         state
       ) do
    with {:ok, state} <- wait_for_server_ready(state) do
      maybe_describe_codecs(
        %EdgeDB.Query{query | capabilities: capabilities},
        in_id,
        out_id,
        state
      )
    end
  end

  defp handle_prepare_query_flow(query, %ErrorResponse{} = message, state) do
    with {:error, exc, state} <- handle_error_response(message, state, query: query),
         {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp maybe_describe_codecs(
         query,
         in_codec_id,
         out_codec_id,
         %State{queries_cache: qc, codecs_storage: cs} = state
       ) do
    input_codec = Codecs.Storage.get(cs, in_codec_id)
    output_codec = Codecs.Storage.get(cs, out_codec_id)

    if is_nil(input_codec) or is_nil(output_codec) do
      describe_codecs_from_query(query, state)
    else
      query = save_query_with_codecs_in_cache(qc, query, input_codec, output_codec)

      {:ok, query, state}
    end
  end

  defp describe_codecs_from_query(query, state) do
    message = %DescribeStatement{aspect: :data_description}

    with {:ok, state} <- send_messages([message, %Sync{}], state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_describe_query_flow(query, message, state)
    end
  end

  defp handle_describe_query_flow(
         %EdgeDB.Query{cardinality: :one} = query,
         %CommandDataDescription{result_cardinality: :no_result},
         state
       ) do
    exc =
      EdgeDB.Error.cardinality_violation_error(
        "can't execute query since expected single result and query doesn't return any data",
        query: query
      )

    with {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp handle_describe_query_flow(
         query,
         %CommandDataDescription{} = message,
         %State{codecs_storage: cs, queries_cache: qc} = state
       ) do
    {input_codec, output_codec} = parse_description_message(message, cs)

    query = save_query_with_codecs_in_cache(qc, query, input_codec, output_codec)

    with {:ok, state} <- wait_for_server_ready(state) do
      {:ok, query, state}
    end
  end

  defp handle_describe_query_flow(query, %ErrorResponse{} = message, state) do
    with {:error, exc, state} <- handle_error_response(message, state, query: query),
         {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp execute_query(%EdgeDB.Query{} = query, params, opts, state) do
    message = %Execute{
      headers: prepare_headers(opts, state),
      arguments: params
    }

    with {:ok, state} <- send_messages([message, %Sync{}], state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_execute_flow(
        query,
        %EdgeDB.Result{cardinality: query.cardinality, required: query.required},
        message,
        state
      )
    end
  end

  defp handle_execute_flow(
         query,
         %EdgeDB.Result{set: encoded_elements} = result,
         %Data{data: [%DataElement{data: data}]},
         state
       ) do
    with {:ok, {message, state}} <- receive_message(state) do
      handle_execute_flow(
        query,
        %EdgeDB.Result{result | set: [data | encoded_elements]},
        message,
        state
      )
    end
  end

  defp handle_execute_flow(
         query,
         %EdgeDB.Result{} = result,
         %CommandComplete{status: status, headers: %{capabilities: capabilities}},
         state
       ) do
    with {:ok, state} <- wait_for_server_ready(state) do
      {:ok, %EdgeDB.Query{query | capabilities: capabilities},
       %EdgeDB.Result{result | statement: status}, state}
    end
  end

  defp handle_execute_flow(query, _result, %ErrorResponse{} = message, state) do
    with {:error, exc, state} <- handle_error_response(message, state, query: query),
         {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp optimistic_execute_query(%EdgeDB.Query{} = query, params, opts, state) do
    message = %OptimisticExecute{
      headers: prepare_headers(opts, state),
      io_format: query.io_format,
      expected_cardinality: query.cardinality,
      command_text: query.statement,
      input_typedesc_id: query.input_codec.type_id,
      output_typedesc_id: query.output_codec.type_id,
      arguments: params
    }

    with {:ok, state} <- send_messages([message, %Sync{}], state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_optimistic_execute_flow(
        query,
        %EdgeDB.Result{cardinality: query.cardinality, required: query.required},
        message,
        opts,
        state
      )
    end
  end

  defp handle_optimistic_execute_flow(
         %EdgeDB.Query{cardinality: :one} = query,
         _result,
         %CommandDataDescription{result_cardinality: :no_result},
         _opts,
         state
       ) do
    exc =
      EdgeDB.Error.cardinality_violation_error(
        "can't execute query since expected single result and query doesn't return any data",
        query: query
      )

    with {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp handle_optimistic_execute_flow(
         query,
         _result,
         %CommandDataDescription{} = message,
         opts,
         %State{codecs_storage: cs, queries_cache: qc} = state
       ) do
    {input_codec, output_codec} = parse_description_message(message, cs)
    query = save_query_with_codecs_in_cache(qc, query, input_codec, output_codec)
    reencoded_params = DBConnection.Query.encode(query, query.params, [])
    execute_query(query, reencoded_params, opts, state)
  end

  defp handle_optimistic_execute_flow(query, result, %CommandComplete{} = message, _opts, state) do
    handle_execute_flow(query, result, message, state)
  end

  defp handle_optimistic_execute_flow(query, result, %Data{} = message, _opts, state) do
    handle_execute_flow(query, result, message, state)
  end

  defp handle_optimistic_execute_flow(query, _result, %ErrorResponse{} = message, _opts, state) do
    with {:error, exc, state} <- handle_error_response(message, state, query: query),
         {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp parse_description_message(
         %CommandDataDescription{
           input_typedesc_id: input_typedesc_id,
           input_typedesc: input_typedesc,
           output_typedesc_id: output_typedesc_id,
           output_typedesc: output_typedesc
         },
         codecs_storage
       ) do
    input_codec =
      Codecs.Storage.get_or_create(codecs_storage, input_typedesc_id, fn ->
        EdgeDB.Protocol.build_codec_from_type_description(codecs_storage, input_typedesc)
      end)

    output_codec =
      Codecs.Storage.get_or_create(codecs_storage, output_typedesc_id, fn ->
        EdgeDB.Protocol.build_codec_from_type_description(codecs_storage, output_typedesc)
      end)

    {input_codec, output_codec}
  end

  defp close_prepared_query(query, %State{} = state) do
    QueriesCache.clear(state.queries_cache, query)
    {:ok, closed_query_result(), state}
  end

  defp start_transaction(opts, %State{} = state) do
    state.transaction_options
    |> Keyword.merge(opts)
    |> QueryBuilder.start_transaction_statement()
    |> execute_script_query(%{allow_capabilities: [:transaction]}, state)
  end

  defp commit_transaction(state) do
    statement = QueryBuilder.commit_transaction_statement()
    execute_script_query(statement, %{allow_capabilities: [:transaction]}, state)
  end

  defp rollback_transaction(state) do
    statement = QueryBuilder.rollback_transaction_statement()
    execute_script_query(statement, %{allow_capabilities: [:transaction]}, state)
  end

  defp execute_script_query(statement, headers, state) do
    message = %ExecuteScript{headers: headers, script: statement}

    with {:ok, state} <- send_message(message, state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_execute_script_flow(message, state)
    end
  end

  defp handle_execute_script_flow(%CommandComplete{status: status}, state) do
    result = %EdgeDB.Result{
      cardinality: :no_result,
      statement: status
    }

    with {:ok, state} <- wait_for_server_ready(state) do
      {:ok, result, state}
    end
  end

  defp handle_execute_script_flow(%ErrorResponse{} = message, state) do
    with {:error, exc, state} <- handle_error_response(message, state),
         {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp handle_error_response(
         %ErrorResponse{
           error_code: code,
           message: message,
           attributes: attributes
         },
         state,
         opts \\ []
       ) do
    exc =
      EdgeDB.Error.exception(message,
        code: code,
        attributes: Enum.into(attributes, %{}),
        query: opts[:query]
      )

    {:error, exc, state}
  end

  defp handle_log_message(%LogMessage{severity: severity, text: text}, state) do
    Logger.log(severity, text)
    state
  end

  defp maybe_ping(%State{ping_interval: :disabled} = state) do
    {:ok, state}
  end

  defp maybe_ping(
         %State{
           ping_interval: nil,
           server_settings: %{
             system_config: config
           }
         } = state
       ) do
    case config[:session_idle_timeout] do
      nil ->
        {:ok, state}

      0 ->
        {:ok, %State{state | ping_interval: :disabled}}

      session_idle_timeout ->
        ping_interval = System.convert_time_unit(session_idle_timeout, :microsecond, :second)
        maybe_ping(%State{state | ping_interval: ping_interval})
    end
  end

  defp maybe_ping(%State{ping_interval: interval, last_active: last_active} = state) do
    if System.monotonic_time(:second) - last_active >= interval do
      do_ping(state)
    else
      {:ok, state}
    end
  end

  defp do_ping(%State{} = state) do
    with {:ok, state} <- send_message(%Sync{}, state) do
      wait_for_server_ready(state)
    end
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

  defp initialize_custom_codecs([], %State{} = state) do
    {:ok, state}
  end

  defp initialize_custom_codecs(codecs_modules, %State{codecs_storage: cs} = state) do
    codecs =
      Enum.map(codecs_modules, fn codec_mod ->
        codec_mod.new()
      end)

    names =
      Enum.map(codecs, fn codec ->
        codec.type_name
      end)

    statement = QueryBuilder.scalars_type_ids_by_names_statement()
    query = DBConnection.Query.parse(%EdgeDB.Query{statement: statement, params: [names]}, [])

    with {:ok, query, state} <- prepare_query(query, [], state),
         encoded_params = DBConnection.Query.encode(query, query.params, []),
         {:ok, query, result, state} <- execute_query(query, encoded_params, [], state),
         result = DBConnection.Query.decode(query, result, []),
         {:ok, types} <- EdgeDB.Result.extract(result) do
      Enum.each(codecs, fn %Codec{type_name: name} = codec ->
        scalar_object =
          Enum.find(types, fn type ->
            type[:name] == name
          end)

        case scalar_object do
          %EdgeDB.Object{id: type_id} ->
            Codecs.Storage.register(cs, %Codec{codec | type_id: type_id})

          _other ->
            Logger.warn("skip registration of codec for unknown type with name #{inspect(name)}")
        end
      end)

      {:ok, state}
    end
  end

  defp parse_system_config(encoded_config, %State{} = state) do
    {%SystemConfig{
       typedesc_id: typedesc_id,
       typedesc: type_descriptor,
       data: %DataElement{data: data}
     }, <<>>} = Types.ParameterStatus.SystemConfig.decode(encoded_config)

    state.codecs_storage
    |> Codecs.Storage.get_or_create(typedesc_id, fn ->
      EdgeDB.Protocol.build_codec_from_type_description(state.codecs_storage, type_descriptor)
    end)
    |> Codec.decode(data)
  end

  defp send_message(message, state) do
    message
    |> EdgeDB.Protocol.encode_message()
    |> send_data_into_socket(state)
  end

  defp send_messages(messages, state) when is_list(messages) do
    messages
    |> Enum.map(&EdgeDB.Protocol.encode_message/1)
    |> send_data_into_socket(state)
  end

  defp receive_message(state) do
    case EdgeDB.Protocol.decode_message(state.buffer) do
      {:ok, {%LogMessage{} = message, buffer}} ->
        state = handle_log_message(message, %State{state | buffer: buffer})
        receive_message(state)

      {:ok, {message, buffer}} ->
        {:ok,
         {message,
          %State{
            state
            | last_active: System.monotonic_time(:second),
              buffer: buffer
          }}}

      {:error, {:not_enough_size, size}} ->
        receive_message_data_from_socket(size, state)
    end
  end

  defp receive_message_data_from_socket(required_data_size, state) do
    case :ssl.recv(state.socket, min(required_data_size, @max_packet_size), state.timeout) do
      {:ok, data} ->
        receive_message(%State{state | buffer: state.buffer <> data})

      {:error, :closed} ->
        exc = EdgeDB.Error.client_connection_closed_error("connection has been closed")
        {:disconnect, exc, state}

      {:error, :etimedout} ->
        exc = EdgeDB.Error.client_connection_timeout_error("exceeded timeout")
        {:disconnect, exc, state}

      {:error, :timeout} ->
        exc = EdgeDB.Error.client_connection_timeout_error("exceeded timeout")
        {:disconnect, exc, state}

      {:error, reason} ->
        exc =
          EdgeDB.Error.client_connection_error(
            "unexpected error while receiving data from socket: #{inspect(reason)}"
          )

        {:disconnect, exc, state}
    end
  end

  defp send_data_into_socket(data, %State{socket: socket} = state) do
    case :ssl.send(socket, data) do
      :ok ->
        {:ok, %State{state | last_active: System.monotonic_time(:second)}}

      {:error, :closed} ->
        exc = EdgeDB.Error.client_connection_closed_error("connection has been closed")
        {:disconnect, exc, state}

      {:error, :etimedout} ->
        exc = EdgeDB.Error.client_connection_timeout_error("exceeded timeout")
        {:disconnect, exc, state}

      {:error, reason} ->
        exc =
          EdgeDB.Error.client_connection_error(
            "unexpected error while receiving data from socket: #{inspect(reason)}"
          )

        {:disconnect, exc, state}
    end
  end

  defp prepare_headers(headers, %State{} = state) do
    state_headers = %{}

    state_headers =
      if state.capabilities != [] do
        Map.put(state_headers, :allow_capabilities, state.capabilities)
      else
        state_headers
      end

    headers = Enum.into(headers, %{})
    Map.merge(state_headers, headers)
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

  defp closed_query_result do
    %EdgeDB.Result{statement: :closed, cardinality: :no_result}
  end
end
