defmodule EdgeDB.Connection do
  @moduledoc false

  use DBConnection

  alias EdgeDB.Connection.{
    InternalRequest,
    QueriesCache,
    QueryBuilder,
    State
  }

  alias EdgeDB.{
    Protocol,
    SCRAM
  }

  alias EdgeDB.Protocol.{
    Codec,
    CodecStorage,
    Enums
  }

  alias EdgeDB.Protocol.Types.{
    ConnectionParam,
    DataElement,
    ParameterStatus.SystemConfig
  }

  alias EdgeDB.Protocol.Messages.Client.{
    AuthenticationSASLInitialResponse,
    AuthenticationSASLResponse,
    ClientHandshake,
    DescribeStatement,
    Execute,
    ExecuteScript,
    OptimisticExecute,
    Prepare,
    Sync,
    Terminate
  }

  alias EdgeDB.Protocol.Messages.Server.{
    AuthenticationOK,
    AuthenticationSASL,
    AuthenticationSASLContinue,
    AuthenticationSASLFinal,
    CommandComplete,
    CommandDataDescription,
    Data,
    ErrorResponse,
    LogMessage,
    ParameterStatus,
    PrepareComplete,
    ReadyForCommand,
    ServerHandshake,
    ServerKeyData
  }

  require Logger

  @tcp_socket_opts [packet: :raw, mode: :binary, active: false]
  @ssl_socket_opts []

  @scram_sha_256 "SCRAM-SHA-256"
  @major_ver 0
  @minor_ver 13
  @minor_ver_min 13
  @edgedb_alpn_protocol "edgedb-binary"
  @message_header_length Protocol.message_header_length()

  defmodule State do
    @moduledoc false

    defstruct [
      :socket,
      :user,
      :database,
      :queries_cache,
      :codec_storage,
      :timeout,
      :pool_pid,
      capabilities: [],
      transaction_options: [],
      retry_options: [],
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
            capabilities: Enums.capabilities(),
            pool_pid: pid() | nil,
            transaction_options: list(EdgeDB.edgedb_transaction_option()),
            retry_options: list(EdgeDB.retry_option()),
            server_key_data: list(byte()) | nil,
            server_state: Enums.transaction_state(),
            queries_cache: QueriesCache.t(),
            codec_storage: CodecStorage.t(),
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

    pool_pid = opts[:pool_pid]
    timeout = opts[:timeout]

    state = %State{
      user: user,
      database: database,
      timeout: timeout,
      pool_pid: pool_pid,
      transaction_options: transaction_opts,
      retry_options: retry_opts
    }

    qc = QueriesCache.new()
    cs = CodecStorage.new()

    with {:ok, socket} <- open_ssl_connection(host, port, tcp_opts, ssl_opts, timeout),
         state = %State{state | socket: socket, queries_cache: qc, codec_storage: cs},
         {:ok, state} <- handshake(password, state),
         {:ok, state} <- wait_for_server_ready(state),
         {:ok, state} <- initialize_custom_codecs(codecs_modules, state) do
      {:ok, state}
    else
      {:error, reason} ->
        exc =
          EdgeDB.ClientConnectionError.new(
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
        %EdgeDB.Error{type: EdgeDB.ClientConnectionClosedError},
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
    exc = EdgeDB.InterfaceError.new("handle_deallocate/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_declare(_query, _params, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_declare/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_execute(%EdgeDB.Query{cached: true} = query, params, opts, state) do
    case optimistic_execute_query(query, params, opts, state) do
      {:ok, query, result, state} ->
        {:ok, %EdgeDB.Query{query | codec_storage: state.codec_storage}, result, state}

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
        {:ok, %EdgeDB.Query{query | codec_storage: state.codec_storage}, result, state}

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
      EdgeDB.InterfaceError.new("unknown internal request to connection: #{inspect(request)}")

    {:error, exc, state}
  end

  @impl DBConnection
  def handle_fetch(_query, _cursor, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_fetch/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_prepare(%EdgeDB.Query{} = query, opts, %State{queries_cache: qc} = state) do
    case QueriesCache.get(qc, query.statement, query.cardinality, query.io_format, query.required) do
      %EdgeDB.Query{} = cached_query ->
        {:ok, %EdgeDB.Query{cached_query | codec_storage: state.codec_storage}, state}

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
      EdgeDB.ClientConnectionError.new(
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
      EdgeDB.AuthenticationError.new(
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
          EdgeDB.AuthenticationError.new(
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
          EdgeDB.AuthenticationError.new(
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

  defp handle_server_ready_flow(
         %ParameterStatus{name: "suggested_pool_concurrency", value: value},
         %State{} = state
       ) do
    {pool_concurrency, ""} = Integer.parse(value)
    inform_pool_about_suggested_size(state.pool_pid, pool_concurrency)

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
      EdgeDB.CardinalityViolationError.new(
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
         %State{queries_cache: qc, codec_storage: cs} = state
       ) do
    if is_nil(CodecStorage.get(cs, in_codec_id)) or is_nil(CodecStorage.get(cs, out_codec_id)) do
      describe_codecs_from_query(query, state)
    else
      query = save_query_with_codecs_in_cache(qc, query, in_codec_id, out_codec_id)

      {:ok, %EdgeDB.Query{query | codec_storage: cs}, state}
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
      EdgeDB.CardinalityViolationError.new(
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
         %State{codec_storage: cs, queries_cache: qc} = state
       ) do
    parse_description_message(message, cs)

    query =
      save_query_with_codecs_in_cache(
        qc,
        query,
        message.input_typedesc_id,
        message.output_typedesc_id
      )

    with {:ok, state} <- wait_for_server_ready(state) do
      {:ok, %EdgeDB.Query{query | codec_storage: cs}, state}
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
      input_typedesc_id: query.input_codec,
      output_typedesc_id: query.output_codec,
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
      EdgeDB.CardinalityViolationError.new(
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
         %State{codec_storage: cs, queries_cache: qc} = state
       ) do
    parse_description_message(message, cs)

    query =
      save_query_with_codecs_in_cache(
        qc,
        query,
        message.input_typedesc_id,
        message.output_typedesc_id
      )

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
         codec_storage
       ) do
    if is_nil(CodecStorage.get(codec_storage, input_typedesc_id)) do
      Protocol.parse_type_description(input_typedesc, codec_storage)
    end

    if is_nil(CodecStorage.get(codec_storage, output_typedesc_id)) do
      Protocol.parse_type_description(output_typedesc, codec_storage)
    end
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
        ping_interval = ping_from_idle_timeout(session_idle_timeout)
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

  defp ping_from_idle_timeout(timeout) when is_integer(timeout) do
    System.convert_time_unit(timeout, :microsecond, :second)
  end

  if Code.ensure_loaded?(Timex) do
    defp ping_from_idle_timeout(%Timex.Duration{} = timeout) do
      Timex.Duration.to_seconds(timeout, truncate: true)
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

  defp initialize_custom_codecs(codecs_modules, %State{codec_storage: cs} = state) do
    names =
      Enum.map(codecs_modules, fn codec_mod ->
        codec_mod.name()
      end)

    statement = QueryBuilder.scalars_type_ids_by_names_statement()
    query = DBConnection.Query.parse(%EdgeDB.Query{statement: statement, params: [names]}, [])

    with {:ok, query, state} <- prepare_query(query, [], state),
         encoded_params = DBConnection.Query.encode(query, query.params, []),
         {:ok, query, result, state} <- execute_query(query, encoded_params, [], state),
         result = DBConnection.Query.decode(query, result, []),
         {:ok, types} <- EdgeDB.Result.extract(result) do
      Enum.each(codecs_modules, fn codec_mod ->
        scalar_object =
          Enum.find(types, fn type ->
            type[:name] == codec_mod.name()
          end)

        case scalar_object do
          %EdgeDB.Object{id: type_id} ->
            CodecStorage.add(cs, type_id, codec_mod.new())

          _other ->
            Logger.warn(
              "skip registration of codec for unknown type with name #{inspect(codec_mod.name())}"
            )
        end
      end)

      {:ok, state}
    end
  end

  defp parse_system_config(encoded_config, %State{} = state) do
    %SystemConfig{
      typedesc_id: typedesc_id,
      typedesc: type_descriptor,
      data: %DataElement{data: data}
    } = Protocol.decode_system_config(encoded_config)

    codec =
      case CodecStorage.get(state.codec_storage, typedesc_id) do
        nil ->
          codec_id = Protocol.parse_type_description(type_descriptor, state.codec_storage)
          CodecStorage.get(state.codec_storage, codec_id)

        codec ->
          codec
      end

    Codec.decode(codec, data, state.codec_storage)
  end

  defp send_message(message, state) do
    message
    |> Protocol.encode_message()
    |> send_data_into_socket(state)
  end

  defp send_messages(messages, state) when is_list(messages) do
    messages
    |> Enum.map(&Protocol.encode_message/1)
    |> send_data_into_socket(state)
  end

  defp receive_message(state) do
    result =
      with {:ok, data} <- :ssl.recv(state.socket, @message_header_length, state.timeout) do
        case Protocol.parse_message_header(data) do
          {type, 0} ->
            {:ok, Protocol.decode_message(type, <<>>)}

          {type, length} ->
            with {:ok, payload} <- :ssl.recv(state.socket, length, state.timeout) do
              {:ok, Protocol.decode_message(type, payload)}
            end
        end
      end

    case result do
      {:ok, %LogMessage{} = message} ->
        state = handle_log_message(message, state)
        receive_message(state)

      {:ok, message} ->
        {:ok, {message, %State{state | last_active: System.monotonic_time(:second)}}}

      {:error, :closed} ->
        exc = EdgeDB.ClientConnectionClosedError.new("connection has been closed")
        {:disconnect, exc, state}

      {:error, :etimedout} ->
        exc = EdgeDB.ClientConnectionTimeoutError.new("exceeded timeout")
        {:disconnect, exc, state}

      {:error, :timeout} ->
        exc = EdgeDB.ClientConnectionTimeoutError.new("exceeded timeout")
        {:disconnect, exc, state}

      {:error, reason} ->
        exc =
          EdgeDB.ClientConnectionError.new(
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
        exc = EdgeDB.ClientConnectionClosedError.new("connection has been closed")
        {:disconnect, exc, state}

      {:error, :etimedout} ->
        exc = EdgeDB.ClientConnectionTimeoutError.new("exceeded timeout")
        {:disconnect, exc, state}

      {:error, reason} ->
        exc =
          EdgeDB.ClientConnectionError.new(
            "unexpected error while receiving data from socket: #{inspect(reason)}"
          )

        {:disconnect, exc, state}
    end
  end

  defp inform_pool_about_suggested_size(nil, _suggested_size) do
    :ok
  end

  defp inform_pool_about_suggested_size(pool_pid, suggested_size) do
    send(pool_pid, {:resize_pool, suggested_size})
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
