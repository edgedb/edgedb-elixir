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

  alias EdgeDB.Protocol.Messages.{Client, Server}

  alias EdgeDB.Protocol.Messages.Client.{
    AuthenticationSASLInitialResponse,
    AuthenticationSASLResponse,
    ClientHandshake,
    Execute,
    Parse,
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
    ReadyForCommand,
    ServerHandshake,
    ServerKeyData,
    StateDataDescription
  }

  require Logger

  @tcp_socket_opts [packet: :raw, mode: :binary, active: false]
  @ssl_socket_opts []

  @scram_sha_256 "SCRAM-SHA-256"
  @supported_authentication_methods [@scram_sha_256]

  @major_version Protocol.major_version()
  @minor_version Protocol.minor_version()

  @min_major_version Protocol.min_major_version()
  @min_minor_version Protocol.min_minor_version()

  @edgedb_alpn_protocol "edgedb-binary"
  @message_header_length Protocol.message_header_length()

  @null_codec_id CodecStorage.null_codec_id()

  defmodule State do
    @moduledoc false

    defstruct [
      :socket,
      :user,
      :database,
      :branch,
      :queries_cache,
      :codec_storage,
      :timeout,
      :pool_pid,
      server_key_data: nil,
      server_state: :not_in_transaction,
      server_settings: %{},
      ping_interval: nil,
      last_active: nil,
      savepoint_id: 0,
      edgeql_state_typedesc_id: CodecStorage.null_codec_id(),
      edgeql_state_cache: nil,
      protocol_version: {Protocol.major_version(), Protocol.minor_version()}
    ]

    @type t() :: %__MODULE__{
            socket: :ssl.sslsocket(),
            user: String.t(),
            database: String.t(),
            branch: String.t(),
            timeout: timeout(),
            pool_pid: pid() | nil,
            server_key_data: list(byte()) | nil,
            server_state: Enums.transaction_state(),
            queries_cache: QueriesCache.t(),
            codec_storage: CodecStorage.t(),
            server_settings: map(),
            ping_interval: integer() | nil | :disabled,
            last_active: integer() | nil,
            savepoint_id: integer(),
            edgeql_state_typedesc_id: Codec.id(),
            edgeql_state_cache: {EdgeDB.Client.State.t(), binary()} | nil,
            protocol_version: {non_neg_integer(), non_neg_integer()}
          }
  end

  @impl DBConnection
  def connect(opts \\ []) do
    {host, port} = opts[:address]
    user = opts[:user]
    password = opts[:password]
    secret_key = opts[:secret_key]
    database = opts[:database]
    branch = opts[:branch]
    codec_modules = Keyword.get(opts, :codecs, [])

    tcp_opts = Keyword.get(opts, :tcp, []) ++ @tcp_socket_opts

    ssl_opts =
      @ssl_socket_opts
      |> Keyword.merge(opts[:ssl] || [])
      |> add_custom_edgedb_ssl_opts(opts)

    pool_pid = opts[:pool_pid]
    timeout = opts[:timeout]

    qc = QueriesCache.new()
    cs = CodecStorage.new()

    state = %State{
      user: user,
      database: database,
      branch: branch,
      timeout: timeout,
      pool_pid: pool_pid,
      queries_cache: qc,
      codec_storage: cs
    }

    with {:ok, socket} <- open_ssl_connection(host, port, tcp_opts, ssl_opts, timeout),
         state = %State{state | socket: socket},
         {:ok, state} <- handshake(password, secret_key, state),
         {:ok, state} <- wait_for_post_connect_server_ready(state),
         {:ok, state} <- initialize_custom_codecs(codec_modules, state) do
      {:ok, state}
    else
      {:error, reason} ->
        exc =
          EdgeDB.ClientConnectionError.new("unable to establish connection: #{inspect(reason)}")

        send(pool_pid, {:disconnected, self(), exc})
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
  def disconnect(%DBConnection.ConnectionError{reason: %EdgeDB.Error{} = exc}, %State{} = state) do
    disconnect(exc, state)
  end

  @impl DBConnection
  def disconnect(%EdgeDB.Error{type: EdgeDB.ClientConnectionClosedError} = exc, %State{} = state) do
    send(state.pool_pid, {:disconnected, self(), exc})
    :ssl.close(state.socket)
  end

  @impl DBConnection
  def disconnect(exc, %State{} = state) do
    send(state.pool_pid, {:disconnected, self(), exc})

    with {:ok, _state} <- send_message(%Terminate{}, state) do
      :ssl.close(state.socket)
    end
  end

  @impl DBConnection
  def ping(%State{socket: socket} = state) do
    :ssl.setopts(state.socket, active: :once)

    receive do
      {:ssl_closed, ^socket} ->
        message = "connection has been closed"
        edgedb_exc = EdgeDB.ClientConnectionClosedError.new(message)

        exc =
          DBConnection.ConnectionError.exception(
            message: message,
            severity: :debug,
            reason: edgedb_exc
          )

        {:disconnect, exc, state}

      {:ssl, ^socket, message_data} ->
        message = Protocol.decode_completed_message(message_data, state.protocol_version)
        handle_ping_message(message, state)

      other ->
        message = "unexpected message from socket received during ping: #{inspect(other)}"
        {:disconect, EdgeDB.InternalClientError.new(message), state}
    after
      0 ->
        :ssl.setopts(state.socket, active: false)
        {:ok, state}
    end
  end

  @impl DBConnection
  def checkout(state) do
    {:ok, state}
  end

  @impl DBConnection
  def handle_status(_opts, state) do
    {status(state), state}
  end

  @impl DBConnection
  def handle_prepare(%EdgeDB.Query{is_script: true} = query, _opts, %State{} = state) do
    query = %EdgeDB.Query{
      query
      | input_codec: @null_codec_id,
        output_codec: @null_codec_id,
        codec_storage: state.codec_storage
    }

    {:ok, query, state}
  end

  @impl DBConnection
  def handle_prepare(%EdgeDB.Query{} = query, opts, %State{protocol_version: {0, _minor}} = state) do
    cached_query =
      QueriesCache.get(
        state.queries_cache,
        query.statement,
        query.output_format,
        query.implicit_limit,
        query.inline_type_names,
        query.inline_type_ids,
        query.inline_object_ids,
        query.cardinality,
        query.required
      )

    case cached_query do
      %EdgeDB.Query{} ->
        {:ok, %EdgeDB.Query{cached_query | codec_storage: state.codec_storage}, state}

      nil ->
        legacy_prepare_query(query, opts, state)
    end
  end

  @impl DBConnection
  def handle_prepare(%EdgeDB.Query{} = query, opts, %State{} = state) do
    cached_query =
      QueriesCache.get(
        state.queries_cache,
        query.statement,
        query.output_format,
        query.implicit_limit,
        query.inline_type_names,
        query.inline_type_ids,
        query.inline_object_ids,
        query.cardinality,
        query.required
      )

    cond do
      cached_query ->
        {:ok, %EdgeDB.Query{cached_query | codec_storage: state.codec_storage}, state}

      # try to avoid Parse by assuming that if user hasn't provided any data
      # and result is not required than we can use NULL codecs for both input/output
      # if we're wrong then EdgeDB will correct us
      query.params == [] and not query.required ->
        query = %EdgeDB.Query{
          query
          | input_codec: CodecStorage.null_codec_id(),
            output_codec: CodecStorage.null_codec_id(),
            codec_storage: state.codec_storage
        }

        {:ok, query, state}

      true ->
        parse_query(query, opts, state)
    end
  end

  # check if params are empty in legacy protocol
  @impl DBConnection
  def handle_execute(
        %EdgeDB.Query{is_script: true, params: params} = query,
        _params,
        _opts,
        %State{protocol_version: {0, _minor}} = state
      )
      when (is_list(params) and params == []) or (is_map(params) and map_size(params) == 0) do
    execution_result =
      legacy_execute_script_query(
        query.statement,
        %{allow_capabilities: [:legacy_execute]},
        state
      )

    case execution_result do
      {:ok, result, state} ->
        {:ok, query, result, state}

      {reason, %EdgeDB.Error{query: nil} = exc, state} ->
        {reason, %EdgeDB.Error{exc | query: query}, state}

      {reason, exc, state} ->
        {reason, exc, state}
    end
  end

  @impl DBConnection
  def handle_execute(
        %EdgeDB.Query{is_script: true} = query,
        _params,
        _opts,
        %State{protocol_version: {0, _minor}} = state
      ) do
    exc =
      EdgeDB.QueryArgumentError.new("EdgeDB 1.0 doesn't support scripts with parameters",
        query: query
      )

    {:error, exc, state}
  end

  @impl DBConnection
  def handle_execute(
        %EdgeDB.Query{is_script: true} = query,
        params,
        opts,
        %State{} = state
      ) do
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
        %EdgeDB.Query{cached: true} = query,
        params,
        opts,
        %State{protocol_version: {0, _minor}} = state
      ) do
    case legacy_optimistic_execute_query(query, params, opts, state) do
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
        %EdgeDB.Query{} = query,
        params,
        opts,
        %State{protocol_version: {0, _minor}} = state
      ) do
    case legacy_execute_query(query, params, opts, state) do
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
        %InternalRequest{request: :execute_granular_flow},
        %{query: %EdgeDB.Query{} = query, params: params},
        opts,
        state
      ) do
    handle_execute(query, params, opts, state)
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :execute_script_flow} = request,
        %{statement: statement, headers: headers},
        _opts,
        %State{protocol_version: {0, _minor}} = state
      ) do
    with {:ok, result, state} <- legacy_execute_script_query(statement, headers, state) do
      {:ok, request, result, state}
    end
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :execute_script_flow} = request,
        %{query: %EdgeDB.Query{} = query, params: params},
        opts,
        %State{} = state
      ) do
    query = %EdgeDB.Query{
      query
      | input_codec: CodecStorage.null_codec_id(),
        output_codec: CodecStorage.null_codec_id(),
        codec_storage: state.codec_storage,
        params: params
    }

    encoded_params = DBConnection.Query.encode(query, query.params, [])

    with {:ok, _query, result, state} <- execute_query(query, encoded_params, opts, state) do
      {:ok, request, result, state}
    end
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :next_savepoint} = request,
        _params,
        _opts,
        %State{} = state
      ) do
    next_savepoint = state.savepoint_id + 1
    {:ok, request, next_savepoint, %State{state | savepoint_id: next_savepoint}}
  end

  @impl DBConnection
  def handle_execute(%InternalRequest{request: request}, _params, _opts, state) do
    exc =
      EdgeDB.InternalClientError.new(
        "unknown internal request to connection: #{inspect(request)}"
      )

    {:error, exc, state}
  end

  @impl DBConnection
  def handle_close(%EdgeDB.Query{} = query, _opts, state) do
    close_prepared_query(query, state)
  end

  @impl DBConnection
  def handle_declare(_query, _params, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_declare/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_fetch(_query, _cursor, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_fetch/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_deallocate(_query, _cursor, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_deallocate/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_begin(_opts, %State{server_state: server_state} = state)
      when server_state in [:in_transaction, :in_failed_transaction] do
    {status(state), state}
  end

  @impl DBConnection
  def handle_begin(opts, state) do
    start_transaction(opts, state)
  end

  @impl DBConnection
  def handle_commit(_opts, %State{server_state: server_state} = state)
      when server_state in [:not_in_transaction, :in_failed_transaction] do
    {status(state), state}
  end

  @impl DBConnection
  def handle_commit(opts, state) do
    commit_transaction(opts, state)
  end

  @impl DBConnection
  def handle_rollback(_opts, %State{server_state: server_state} = state)
      when server_state == :not_in_transaction do
    {status(state), state}
  end

  @impl DBConnection
  def handle_rollback(opts, state) do
    rollback_transaction(opts, state)
  end

  defp open_ssl_connection(host, port, tcp_opts, ssl_opts, timeout) do
    host = to_charlist(host)
    opts = Keyword.merge(tcp_opts, ssl_opts)

    with {:ok, socket} <- :ssl.connect(host, port, opts, timeout),
         {:ok, @edgedb_alpn_protocol} <- :ssl.negotiated_protocol(socket) do
      {:ok, socket}
    end
  end

  defp add_custom_edgedb_ssl_opts(socket_opts, connect_opts) do
    {socket_opts, self_signed?} =
      case connect_opts[:tls_ca] do
        nil ->
          {Keyword.put(socket_opts, :cacertfile, CAStore.file_path()), false}

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

          {Keyword.put(socket_opts, :cacerts, [der_cert_data]),
           :public_key.pkix_is_self_signed(der_cert_data)}
      end

    socket_opts =
      case connect_opts[:tls_security] do
        :strict ->
          match_fun = :public_key.pkix_verify_hostname_match_fun(:https)

          Keyword.merge(socket_opts,
            verify: :verify_peer,
            customize_hostname_check: [match_fun: match_fun]
          )

        :no_host_verification ->
          verify_fn = fn
            _cert, {:bad_cert, :selfsigned_peer}, us when self_signed? ->
              {:valid, us}

            _cert, {:bad_cert, :hostname_check_failed}, us ->
              {:valid, us}

            _cert, {:bad_cert, _reason} = reason, _us ->
              {:fail, reason}

            _cert, {:extension, _ext}, us ->
              {:unknown, us}

            _cert, :valid, us ->
              {:valid, us}

            _cert, :valid_peer, us ->
              {:valid, us}
          end

          Keyword.put(socket_opts, :verify_fun, {verify_fn, []})

        :insecure ->
          Keyword.put(socket_opts, :verify, :verify_none)
      end

    socket_opts =
      if connect_opts[:tls_server_name] do
        Keyword.put(socket_opts, :server_name_indication, connect_opts[:tls_server_name])
      else
        socket_opts
      end

    Keyword.put(socket_opts, :alpn_advertised_protocols, [@edgedb_alpn_protocol])
  end

  defp handshake(password, secret_key, %State{} = state) do
    params = [
      %ConnectionParam{
        name: "user",
        value: state.user
      },
      %ConnectionParam{
        name: "database",
        value: state.database
      },
      %ConnectionParam{
        name: "branch",
        value: state.branch
      }
    ]

    params =
      if secret_key do
        [%ConnectionParam{name: "secret_key", value: secret_key} | params]
      else
        params
      end

    message = %ClientHandshake{
      major_ver: @major_version,
      minor_ver: @minor_version,
      params: params,
      extensions: []
    }

    with {:ok, state} <- send_message(message, state) do
      authenticate(password, state)
    end
  end

  defp authenticate(password, state) do
    with {:ok, {message, state}} <- receive_message(state) do
      handle_authentication_flow(message, password, state)
    end
  end

  defp authenticate(@scram_sha_256, password, %State{} = state) do
    {server_first, cf_data} = EdgeDB.SCRAM.handle_client_first(state.user, password)

    message = %AuthenticationSASLInitialResponse{
      method: @scram_sha_256,
      sasl_data: cf_data
    }

    with {:ok, state} <- send_message(message, state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_scram_sha_256_authentication_flow(message, server_first, state)
    end
  end

  defp handle_authentication_flow(
         %ServerHandshake{major_ver: major_version, minor_ver: minor_version},
         _password,
         state
       )
       when major_version < @min_major_version or @major_version < major_version or
              (major_version == @min_major_version and minor_version < @min_minor_version) do
    exc =
      EdgeDB.ClientConnectionError.new(
        "the server requested an unsupported version of the protocol #{major_version}.#{minor_version}"
      )

    {:disconnect, exc, state}
  end

  defp handle_authentication_flow(
         %ServerHandshake{} = message,
         password,
         %State{} = state
       ) do
    protocol = {message.major_ver, message.minor_ver}

    with {:ok, {message, state}} <- receive_message(%State{state | protocol_version: protocol}) do
      handle_authentication_flow(message, password, state)
    end
  end

  defp handle_authentication_flow(%AuthenticationOK{}, _password, state) do
    {:ok, state}
  end

  defp handle_authentication_flow(%AuthenticationSASL{}, nil, %State{} = state) do
    exc =
      EdgeDB.AuthenticationError.new(
        "password should be provided for #{inspect(state.user)} authentication"
      )

    {:disconnect, exc, state}
  end

  defp handle_authentication_flow(%AuthenticationSASL{methods: methods}, password, state) do
    case Enum.find(methods, &(&1 in @supported_authentication_methods)) do
      nil ->
        exc =
          EdgeDB.AuthenticationError.new(
            "EdgeDB requested unsupported authentication methods: #{inspect(methods)}"
          )

        {:disconnect, exc, state}

      method ->
        authenticate(method, password, state)
    end
  end

  defp handle_authentication_flow(%ErrorResponse{} = message, _password, state) do
    handle_error_response(message, state)
  end

  defp handle_scram_sha_256_authentication_flow(
         %AuthenticationSASLContinue{sasl_data: data},
         %SCRAM.ServerFirst{} = server_first,
         state
       ) do
    with {:ok, {server_final, client_final_data}} <-
           EdgeDB.SCRAM.handle_server_first(server_first, data),
         {:ok, state} <-
           send_message(%AuthenticationSASLResponse{sasl_data: client_final_data}, state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_scram_sha_256_authentication_flow(message, server_final, state)
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

  defp handle_scram_sha_256_authentication_flow(
         %AuthenticationSASLFinal{sasl_data: data},
         %SCRAM.ServerFinal{} = server_final,
         state
       ) do
    with :ok <- EdgeDB.SCRAM.handle_server_final(server_final, data),
         {:ok, {message, state}} <- receive_message(state) do
      handle_scram_sha_256_authentication_flow(message, state)
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

  defp handle_scram_sha_256_authentication_flow(%ErrorResponse{} = message, _scram_data, state) do
    handle_error_response(message, state)
  end

  defp handle_scram_sha_256_authentication_flow(%AuthenticationOK{}, state) do
    {:ok, state}
  end

  defp handle_scram_sha_256_authentication_flow(%ErrorResponse{} = message, state) do
    handle_error_response(message, state)
  end

  defp wait_for_post_connect_server_ready(state) do
    with {:ok, {message, state}} <- receive_message(state) do
      handle_post_connect_server_ready_waiting_flow(message, state)
    end
  end

  defp handle_post_connect_server_ready_waiting_flow(%ServerKeyData{data: data}, %State{} = state) do
    wait_for_post_connect_server_ready(%State{state | server_key_data: data})
  end

  defp handle_post_connect_server_ready_waiting_flow(%StateDataDescription{} = message, state) do
    with {:ok, state} <- describe_state(message, state) do
      wait_for_post_connect_server_ready(state)
    end
  end

  defp handle_post_connect_server_ready_waiting_flow(%ParameterStatus{} = message, state) do
    with {:ok, state} <- handle_parameter_status(message, state) do
      wait_for_post_connect_server_ready(state)
    end
  end

  defp handle_post_connect_server_ready_waiting_flow(
         %ReadyForCommand{transaction_state: transaction_state},
         %State{} = state
       ) do
    {:ok, %State{state | server_state: transaction_state}}
  end

  defp handle_post_connect_server_ready_waiting_flow(%ErrorResponse{} = message, state) do
    handle_error_response(message, state)
  end

  defp wait_for_server_ready(state) do
    with {:ok, {message, state}} <- receive_message(state) do
      handle_server_ready_flow(message, state)
    end
  end

  defp handle_server_ready_flow(%ParameterStatus{} = message, state) do
    with {:ok, state} <- handle_parameter_status(message, state) do
      wait_for_server_ready(state)
    end
  end

  defp handle_server_ready_flow(
         %ReadyForCommand{transaction_state: transaction_state},
         %State{} = state
       ) do
    {:ok, %State{state | server_state: transaction_state}}
  end

  defp handle_server_ready_flow(%ErrorResponse{} = message, state) do
    handle_error_response(message, state)
  end

  defp handle_parameter_status(
         %ParameterStatus{name: "suggested_pool_concurrency", value: pool_concurrency},
         %State{} = state
       ) do
    inform_pool_about_suggested_concurrency(state.pool_pid, pool_concurrency)
    server_settings = Map.put(state.server_settings, :pool_concurrency, pool_concurrency)
    {:ok, %State{state | server_settings: server_settings}}
  end

  defp handle_parameter_status(
         %ParameterStatus{name: "system_config", value: system_config},
         %State{} = state
       ) do
    system_config = parse_system_config(system_config, state)
    server_settings = Map.put(state.server_settings, :system_config, system_config)
    {:ok, %State{state | server_settings: server_settings}}
  end

  defp handle_parameter_status(%ParameterStatus{}, state) do
    {:ok, state}
  end

  defp parse_query(%EdgeDB.Query{} = query, opts, %State{} = state) do
    capabilities = prepare_capabilities(query, opts[:capabilities], state)
    compilation_flags = prepare_compilation_flags(query)

    {state_data, state} = encode_edgeql_state(opts[:edgeql_state], state)

    message = %Parse{
      annotations: %{},
      allowed_capabilities: capabilities,
      compilation_flags: compilation_flags,
      implicit_limit: query.implicit_limit,
      output_format: query.output_format,
      expected_cardinality: query.cardinality,
      command_text: query.statement,
      state_typedesc_id: state.edgeql_state_typedesc_id,
      state_data: state_data
    }

    with {:ok, state} <- send_messages([message, %Sync{}], state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_parse_flow(query, message, state)
    end
  end

  # this says that our state descriptor ID is invalid and
  # we will receive StateMismatchError soon
  defp handle_parse_flow(query, %StateDataDescription{} = message, state) do
    with {:ok, state} <- describe_state(message, state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_parse_flow(query, message, state)
    end
  end

  defp handle_parse_flow(
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

  defp handle_parse_flow(
         %EdgeDB.Query{} = query,
         %CommandDataDescription{} = message,
         %State{} = state
       ) do
    parse_description_message(message, state.codec_storage, state.protocol_version)

    query =
      save_query_with_codecs_in_cache(
        state.queries_cache,
        query,
        message.input_typedesc_id,
        message.output_typedesc_id
      )

    with {:ok, state} <- wait_for_server_ready(state) do
      {:ok, %EdgeDB.Query{query | codec_storage: state.codec_storage}, state}
    end
  end

  defp handle_parse_flow(query, %ErrorResponse{} = message, state) do
    with {:error, exc, state} <- handle_error_response(message, state, query: query),
         {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp legacy_prepare_query(%EdgeDB.Query{} = query, opts, state) do
    message = %Client.V0.Prepare{
      headers: prepare_legacy_headers(query, opts, state),
      io_format: query.output_format,
      expected_cardinality: query.cardinality,
      command: query.statement
    }

    with {:ok, state} <- send_messages([message, %Sync{}], state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_legacy_prepare_flow(query, message, state)
    end
  end

  defp handle_legacy_prepare_flow(
         %EdgeDB.Query{cardinality: :one} = query,
         %Server.V0.PrepareComplete{
           cardinality: :no_result,
           headers: %{capabilities: capabilities}
         },
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

  defp handle_legacy_prepare_flow(
         query,
         %Server.V0.PrepareComplete{
           input_typedesc_id: in_id,
           output_typedesc_id: out_id,
           headers: %{capabilities: capabilities}
         },
         state
       ) do
    with {:ok, state} <- wait_for_server_ready(state) do
      maybe_legacy_describe_codecs(
        %EdgeDB.Query{query | capabilities: capabilities},
        in_id,
        out_id,
        state
      )
    end
  end

  defp handle_legacy_prepare_flow(query, %ErrorResponse{} = message, state) do
    with {:error, exc, state} <- handle_error_response(message, state, query: query),
         {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp maybe_legacy_describe_codecs(
         query,
         in_codec_id,
         out_codec_id,
         %State{} = state
       ) do
    if is_nil(CodecStorage.get(state.codec_storage, in_codec_id)) or
         is_nil(CodecStorage.get(state.codec_storage, out_codec_id)) do
      legacy_describe_codecs_from_query(query, state)
    else
      query =
        save_query_with_codecs_in_cache(state.queries_cache, query, in_codec_id, out_codec_id)

      {:ok, %EdgeDB.Query{query | codec_storage: state.codec_storage}, state}
    end
  end

  defp legacy_describe_codecs_from_query(query, state) do
    message = %Client.V0.DescribeStatement{aspect: :data_description}

    with {:ok, state} <- send_messages([message, %Sync{}], state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_legacy_describe_query_flow(query, message, state)
    end
  end

  defp handle_legacy_describe_query_flow(
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

  defp handle_legacy_describe_query_flow(
         query,
         %CommandDataDescription{} = message,
         %State{} = state
       ) do
    parse_description_message(message, state.codec_storage, state.protocol_version)

    query =
      save_query_with_codecs_in_cache(
        state.queries_cache,
        query,
        message.input_typedesc_id,
        message.output_typedesc_id
      )

    with {:ok, state} <- wait_for_server_ready(state) do
      {:ok, %EdgeDB.Query{query | codec_storage: state.codec_storage}, state}
    end
  end

  defp handle_legacy_describe_query_flow(query, %ErrorResponse{} = message, state) do
    with {:error, exc, state} <- handle_error_response(message, state, query: query),
         {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp legacy_execute_query(%EdgeDB.Query{} = query, params, opts, state) do
    message = %Client.V0.Execute{
      headers: prepare_legacy_headers(query, opts, state),
      arguments: params
    }

    with {:ok, state} <- send_messages([message, %Sync{}], state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_execute_flow(
        query,
        %EdgeDB.Result{cardinality: query.cardinality, required: query.required},
        opts,
        message,
        state
      )
    end
  end

  defp execute_query(%EdgeDB.Query{} = query, params, opts, %State{} = state) do
    capabilities = prepare_capabilities(query, opts[:capabilities], state)
    compilation_flags = prepare_compilation_flags(query)

    {state_data, state} = encode_edgeql_state(opts[:edgeql_state], state)

    message = %Execute{
      annotations: %{},
      allowed_capabilities: capabilities,
      compilation_flags: compilation_flags,
      implicit_limit: query.implicit_limit,
      output_format: query.output_format,
      expected_cardinality: query.cardinality,
      command_text: query.statement,
      state_typedesc_id: state.edgeql_state_typedesc_id,
      state_data: state_data,
      input_typedesc_id: query.input_codec || CodecStorage.null_codec_id(),
      output_typedesc_id: query.output_codec || CodecStorage.null_codec_id(),
      arguments: params
    }

    with {:ok, state} <- send_messages([message, %Sync{}], state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_execute_flow(
        query,
        %EdgeDB.Result{cardinality: query.cardinality, required: query.required},
        opts,
        message,
        state
      )
    end
  end

  # this says that our codecs are stale and
  # we will receive ParameterTypeMismatchError soon
  # after that message

  defp handle_execute_flow(
         %EdgeDB.Query{cardinality: :one} = query,
         _result,
         _opts,
         %CommandDataDescription{result_cardinality: :no_result, capabilities: capabilities},
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

  defp handle_execute_flow(
         %EdgeDB.Query{} = query,
         result,
         opts,
         %CommandDataDescription{capabilities: capabilities} = message,
         %State{} = state
       ) do
    parse_description_message(message, state.codec_storage, state.protocol_version)

    query =
      save_query_with_codecs_in_cache(
        state.queries_cache,
        %EdgeDB.Query{query | capabilities: capabilities},
        message.input_typedesc_id,
        message.output_typedesc_id
      )

    with {:ok, {message, state}} <- receive_message(state) do
      handle_execute_flow(query, result, opts, message, state)
    end
  end

  # this says that our state descritor ID is invalid and
  # we will receive StateMismatchError soon
  defp handle_execute_flow(query, result, opts, %StateDataDescription{} = message, state) do
    with {:ok, state} <- describe_state(message, state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_execute_flow(query, result, opts, message, state)
    end
  end

  defp handle_execute_flow(
         query,
         %EdgeDB.Result{set: encoded_elements} = result,
         opts,
         %Data{data: [%DataElement{data: data}]},
         state
       ) do
    with {:ok, {message, state}} <- receive_message(state) do
      handle_execute_flow(
        query,
        %EdgeDB.Result{result | set: [data | encoded_elements]},
        opts,
        message,
        state
      )
    end
  end

  # legacy: in EdgeDB 1.0 capabilities were stored in headers
  defp handle_execute_flow(
         query,
         %EdgeDB.Result{} = result,
         _opts,
         %CommandComplete{status: status, __headers__: %{capabilities: capabilities}},
         %State{protocol_version: {0, _minor}} = state
       ) do
    with {:ok, state} <- wait_for_server_ready(state) do
      query = %EdgeDB.Query{query | capabilities: capabilities}
      result = %EdgeDB.Result{result | statement: status}
      {:ok, query, result, state}
    end
  end

  defp handle_execute_flow(
         query,
         %EdgeDB.Result{} = result,
         _opts,
         %CommandComplete{status: status, capabilities: capabilities},
         state
       ) do
    with {:ok, state} <- wait_for_server_ready(state) do
      query = %EdgeDB.Query{query | capabilities: capabilities}
      result = %EdgeDB.Result{result | statement: status}
      {:ok, query, result, state}
    end
  end

  defp handle_execute_flow(query, _result, opts, %ErrorResponse{} = message, state) do
    with {:error, exc, state} <- handle_error_response(message, state, query: query) do
      handle_execution_error_flow(query, exc, opts, state)
    end
  end

  # at this stage client should already process CommandDataDescription and store new codecs in query
  # so we can retry execution
  defp handle_execution_error_flow(
         query,
         %EdgeDB.Error{type: EdgeDB.ParameterTypeMismatchError},
         opts,
         state
       ) do
    with {:ok, state} <- wait_for_server_ready(state) do
      reencoded_params = DBConnection.Query.encode(query, query.params, [])
      execute_query(query, reencoded_params, opts, state)
    end
  end

  defp handle_execution_error_flow(_query, exc, _opts, state) do
    with {:ok, state} <- wait_for_server_ready(state) do
      {:error, exc, state}
    end
  end

  defp describe_state(%StateDataDescription{} = message, %State{} = state) do
    if is_nil(CodecStorage.get(state.codec_storage, message.typedesc_id)) do
      Protocol.parse_type_description(
        message.typedesc,
        state.codec_storage,
        state.protocol_version
      )
    end

    {:ok, %State{state | edgeql_state_typedesc_id: message.typedesc_id}}
  end

  defp legacy_optimistic_execute_query(%EdgeDB.Query{} = query, params, opts, state) do
    message = %Client.V0.OptimisticExecute{
      headers: prepare_legacy_headers(query, opts, state),
      io_format: query.output_format,
      expected_cardinality: query.cardinality,
      command_text: query.statement,
      input_typedesc_id: query.input_codec,
      output_typedesc_id: query.output_codec,
      arguments: params
    }

    with {:ok, state} <- send_messages([message, %Sync{}], state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_legacy_optimistic_execute_flow(
        query,
        %EdgeDB.Result{cardinality: query.cardinality, required: query.required},
        opts,
        message,
        state
      )
    end
  end

  defp handle_legacy_optimistic_execute_flow(
         %EdgeDB.Query{cardinality: :one} = query,
         _result,
         _opts,
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

  defp handle_legacy_optimistic_execute_flow(
         query,
         _result,
         opts,
         %CommandDataDescription{} = message,
         %State{} = state
       ) do
    parse_description_message(message, state.codec_storage, state.protocol_version)

    query =
      save_query_with_codecs_in_cache(
        state.queries_cache,
        query,
        message.input_typedesc_id,
        message.output_typedesc_id
      )

    reencoded_params = DBConnection.Query.encode(query, query.params, [])
    legacy_execute_query(query, reencoded_params, opts, state)
  end

  defp handle_legacy_optimistic_execute_flow(
         query,
         result,
         opts,
         %CommandComplete{} = message,
         state
       ) do
    handle_execute_flow(query, result, opts, message, state)
  end

  defp handle_legacy_optimistic_execute_flow(query, result, opts, %Data{} = message, state) do
    handle_execute_flow(query, result, opts, message, state)
  end

  defp handle_legacy_optimistic_execute_flow(
         query,
         _result,
         _opts,
         %ErrorResponse{} = message,
         state
       ) do
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
         codec_storage,
         protocol
       ) do
    if is_nil(CodecStorage.get(codec_storage, input_typedesc_id)) do
      Protocol.parse_type_description(input_typedesc, codec_storage, protocol)
    end

    if is_nil(CodecStorage.get(codec_storage, output_typedesc_id)) do
      Protocol.parse_type_description(output_typedesc, codec_storage, protocol)
    end
  end

  defp close_prepared_query(query, %State{} = state) do
    QueriesCache.clear(state.queries_cache, query)
    {:ok, closed_query_result(), state}
  end

  defp start_transaction(opts, %State{protocol_version: {0, _minor}} = state) do
    opts
    |> Keyword.get(:transaction_options, [])
    |> QueryBuilder.start_transaction_statement()
    |> legacy_execute_script_query(%{allow_capabilities: [:transaction]}, state)
  end

  defp start_transaction(opts, %State{} = state) do
    statement =
      opts
      |> Keyword.get(:transaction_options, [])
      |> QueryBuilder.start_transaction_statement()

    with {:ok, _query, result, state} <- execute_transaction_query(statement, opts, state) do
      {:ok, result, state}
    end
  end

  defp commit_transaction(_opts, %State{protocol_version: {0, _minor}} = state) do
    statement = QueryBuilder.commit_transaction_statement()
    legacy_execute_script_query(statement, %{allow_capabilities: [:transaction]}, state)
  end

  defp commit_transaction(opts, state) do
    statement = QueryBuilder.commit_transaction_statement()

    with {:ok, _query, result, state} <- execute_transaction_query(statement, opts, state) do
      {:ok, result, state}
    end
  end

  defp rollback_transaction(_opts, %State{protocol_version: {0, _minor}} = state) do
    statement = QueryBuilder.rollback_transaction_statement()
    legacy_execute_script_query(statement, %{allow_capabilities: [:transaction]}, state)
  end

  defp rollback_transaction(opts, state) do
    statement = QueryBuilder.rollback_transaction_statement()

    with {:ok, _query, result, state} <- execute_transaction_query(statement, opts, state) do
      {:ok, result, state}
    end
  end

  defp execute_transaction_query(statement, opts, %State{} = state) do
    query =
      DBConnection.Query.parse(
        %EdgeDB.Query{
          statement: statement,
          output_format: :none,
          codec_storage: state.codec_storage,
          input_codec: CodecStorage.null_codec_id(),
          output_codec: CodecStorage.null_codec_id()
        },
        []
      )

    capabilities = [:transaction | Keyword.get(opts, :capabilities, [])]
    opts = Keyword.put(opts, :capabilities, capabilities)

    params = DBConnection.Query.encode(query, [], [])
    execute_query(query, params, opts, state)
  end

  defp legacy_execute_script_query(statement, %{} = headers, state) do
    message = %Client.V0.ExecuteScript{
      headers: headers,
      script: statement
    }

    with {:ok, state} <- send_message(message, state),
         {:ok, {message, state}} <- receive_message(state) do
      handle_legacy_execute_script_flow(message, state)
    end
  end

  defp handle_legacy_execute_script_flow(%CommandComplete{status: status}, state) do
    result = %EdgeDB.Result{
      cardinality: :no_result,
      statement: status
    }

    with {:ok, state} <- wait_for_server_ready(state) do
      {:ok, result, state}
    end
  end

  defp handle_legacy_execute_script_flow(%ErrorResponse{} = message, state) do
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

  defp handle_ping_message(%ErrorResponse{} = error_response, state) do
    case handle_error_response(error_response, state) do
      {:error, %EdgeDB.Error{type: EdgeDB.IdleSessionTimeoutError} = error, state} ->
        exc =
          DBConnection.ConnectionError.exception(
            message: error.message,
            severity: :debug,
            reason: error
          )

        {:disconnect, exc, state}

      {:error, exc, state} ->
        {:disconnect, exc, state}
    end
  end

  defp handle_ping_message(message, state) do
    exc =
      EdgeDB.InternalClientError.new(
        "unexpected EdgeDB message received during ping: #{inspect(message)}"
      )

    {:disconect, exc, state}
  end

  # if we haven't received state ID from EdgeDB then pretend state is default
  defp encode_edgeql_state(
         _edgeql_state,
         %State{edgeql_state_typedesc_id: @null_codec_id} = state
       ) do
    codec = CodecStorage.get(state.codec_storage, @null_codec_id)
    state_data = Codec.encode(codec, nil, state.codec_storage)
    {state_data, state}
  end

  # missing state is ok for codecs or substransaction initialization
  defp encode_edgeql_state(nil, state) do
    codec = CodecStorage.get(state.codec_storage, @null_codec_id)
    state_data = Codec.encode(codec, nil, state.codec_storage)
    {state_data, state}
  end

  defp encode_edgeql_state(edgeql_state, %State{} = state) do
    case state.edgeql_state_cache do
      {^edgeql_state, state_data} ->
        {state_data, state}

      _other ->
        codec = CodecStorage.get(state.codec_storage, state.edgeql_state_typedesc_id)

        state_data =
          Codec.encode(codec, EdgeDB.Client.State.to_encodable(edgeql_state), state.codec_storage)

        {state_data, %State{state | edgeql_state_cache: {edgeql_state, state_data}}}
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

  defp initialize_custom_codecs([], state) do
    {:ok, state}
  end

  defp initialize_custom_codecs(codec_modules, %State{} = state) do
    with {:ok, types, state} <- introspect_schema_for_scalar_codecs(codec_modules, state) do
      register_known_codecs(state.codec_storage, codec_modules, types)

      {:ok, state}
    end
  end

  defp introspect_schema_for_scalar_codecs(codec_modules, state) do
    names = Enum.map(codec_modules, fn codec_mod -> codec_mod.name() end)
    statement = QueryBuilder.scalars_type_ids_by_names_statement()
    query = DBConnection.Query.parse(%EdgeDB.Query{statement: statement, params: [names]}, [])

    {parse_fn, execute_fn} =
      case state do
        %State{protocol_version: {0, _minor}} ->
          {&legacy_prepare_query/3, &legacy_execute_query/4}

        _other ->
          {&parse_query/3, &execute_query/4}
      end

    # use default state here, since it's connection initialization and we don't have any real state here
    with {:ok, query, state} <- parse_fn.(query, [edgeql_state: %EdgeDB.Client.State{}], state),
         encoded_params = DBConnection.Query.encode(query, query.params, []),
         {:ok, query, result, state} <-
           execute_fn.(query, encoded_params, [edgeql_state: %EdgeDB.Client.State{}], state),
         result = DBConnection.Query.decode(query, result, []),
         {:ok, types} <- EdgeDB.Result.extract(result) do
      {:ok, types, state}
    end
  end

  defp register_known_codecs(storage, codec_modules, types) do
    Enum.each(codec_modules, fn codec_mod ->
      scalar_object =
        Enum.find(types, fn type ->
          type[:name] == codec_mod.name()
        end)

      case scalar_object do
        %EdgeDB.Object{id: type_id} ->
          CodecStorage.add(storage, type_id, codec_mod.new())

        _other ->
          Logger.warning(
            "skip registration of codec for unknown type " <>
              "with name #{inspect(codec_mod.name())}"
          )
      end
    end)
  end

  defp parse_system_config(
         %SystemConfig{
           typedesc_id: typedesc_id,
           typedesc: type_descriptor,
           data: %DataElement{data: data}
         },
         %State{} = state
       ) do
    codec =
      case CodecStorage.get(state.codec_storage, typedesc_id) do
        nil ->
          codec_id =
            Protocol.parse_type_description(
              type_descriptor,
              state.codec_storage,
              state.protocol_version
            )

          CodecStorage.get(state.codec_storage, codec_id)

        codec ->
          codec
      end

    Codec.decode(codec, data, state.codec_storage)
  end

  defp send_message(message, state) do
    message
    |> Protocol.encode_message(state.protocol_version)
    |> send_data_into_socket(state)
  end

  defp send_messages(messages, state) when is_list(messages) do
    messages
    |> Enum.map(&Protocol.encode_message(&1, state.protocol_version))
    |> send_data_into_socket(state)
  end

  defp receive_message(%State{} = state) do
    result =
      with {:ok, data} <- :ssl.recv(state.socket, @message_header_length, state.timeout) do
        case Protocol.parse_message_header(data) do
          {type, 0} ->
            {:ok, Protocol.decode_message(type, <<>>, state.protocol_version)}

          {type, length} ->
            with {:ok, payload} <- :ssl.recv(state.socket, length, state.timeout) do
              {:ok, Protocol.decode_message(type, payload, state.protocol_version)}
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

  defp send_data_into_socket(data, %State{} = state) do
    case :ssl.send(state.socket, data) do
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

  defp inform_pool_about_suggested_concurrency(nil, _suggested_concurrency) do
    :ok
  end

  defp inform_pool_about_suggested_concurrency(pool_pid, suggested_concurrency) do
    send(pool_pid, {:concurrency_suggest, suggested_concurrency})
  end

  # explicit capabilities
  defp prepare_capabilities(_query, [_cap | _other] = capabilities, _state) do
    capabilities
  end

  # capabilities from parsed query
  defp prepare_capabilities(%EdgeDB.Query{capabilities: [_cap | _other]} = query, _opts, _state) do
    query.capabilities
  end

  # default capabilities to execute any common query (select/insert/etc) in legacy protocol
  defp prepare_capabilities(_query, _opts, %State{protocol_version: {0, _minor}}) do
    [:legacy_execute]
  end

  # default capabilities to execute any common query (select/insert/etc) in protocol
  defp prepare_capabilities(_query, _opts, _state) do
    [:execute]
  end

  defp prepare_legacy_headers(query, %{capabilities: capabilities} = headers, state) do
    Map.merge(headers, %{allow_capabilities: prepare_capabilities(query, capabilities, state)})
  end

  defp prepare_legacy_headers(query, opts, state) when is_list(opts) do
    headers = Enum.into(opts, %{})
    prepare_legacy_headers(query, headers, state)
  end

  # just use default capabilities
  defp prepare_legacy_headers(query, headers, state) do
    Map.merge(headers, %{allow_capabilities: prepare_capabilities(query, [], state)})
  end

  defp prepare_compilation_flags(%EdgeDB.Query{} = query) do
    Enum.reject(
      [
        query.inline_type_ids && :inject_output_type_ids,
        query.inline_type_names && :inject_output_type_names,
        query.inline_object_ids && :inject_output_object_ids
      ],
      &is_boolean/1
    )
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
