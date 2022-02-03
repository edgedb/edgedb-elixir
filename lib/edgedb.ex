defmodule EdgeDB do
  alias EdgeDB.Connection.{
    Config,
    InternalRequest
  }

  alias EdgeDB.Protocol.{
    Enums,
    Error
  }

  @type connection() :: DBConnection.conn() | EdgeDB.WrappedConnection.t()
  @type tls_security() :: :insecure | :no_host_verification | :strict | :default

  # NOTE: :command_timeout and :server_settings
  # options added only for compatability with other drivers and aren't used right now
  @type connect_option() ::
          {:dsn, String.t()}
          | {:credentials, String.t()}
          | {:credentials_file, Path.t()}
          | {:host, String.t()}
          | {:port, :inet.port_number()}
          | {:database, String.t()}
          | {:user, String.t()}
          | {:password, String.t()}
          | {:tls_ca, String.t()}
          | {:tls_ca_file, Path.t()}
          | {:tls_security, tls_security()}
          | {:timeout, timeout()}
          | {:command_timeout, timeout()}
          | {:server_settings, map()}
          | {:tcp, list(:gen_tcp.option())}
          | {:ssl, list(:ssl.tls_client_option())}
          | {:transaction, list(transaction_option())}
          | {:retry, list(retry_option())}

  @type start_option() ::
          connect_option()
          | DBConnection.start_option()

  @type query_option() ::
          {:cardinality, Enums.Cardinality.t()}
          | {:io_format, Enums.IOFormat.t()}
          | {:retry, list(retry_option())}
          | DBConnection.option()

  @type edgedb_transaction_option() ::
          {:isolation, :repeatable_read | :serializable}
          | {:readonly, boolean()}
          | {:deferrable, boolean()}

  @type transaction_option() ::
          edgedb_transaction_option()
          | {:retry, list(retry_option())}
          | DBConnection.option()

  @type rollback_option() ::
          {:reason, term()}
          | {:continue, boolean()}

  @type retry_rule() ::
          {:attempts, pos_integer()}
          | {:backoff, (pos_integer() -> timeout())}

  @type retry_option() ::
          {:transaction_conflict, retry_rule()}
          | {:network_error, retry_rule()}

  @type as_readonly_option() :: {atom(), any()}

  @type raw_result() :: {EdgeDB.Query.t(), EdgeDB.Result.t()}
  @type result() :: EdgeDB.Set.t() | term() | raw_result()

  def start_link(opts \\ [])

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(dsn) when is_binary(dsn) do
    opts = Config.connect_opts(dsn: dsn)
    DBConnection.start_link(EdgeDB.Connection, opts)
  end

  @spec start_link(list(start_option())) :: GenServer.on_start()
  def start_link(opts) do
    opts = Config.connect_opts(opts)
    DBConnection.start_link(EdgeDB.Connection, opts)
  end

  @spec start_link(String.t(), list(start_option())) :: GenServer.on_start()
  def start_link(dsn, opts) do
    opts =
      opts
      |> Keyword.put(:dsn, dsn)
      |> Config.connect_opts()

    DBConnection.start_link(EdgeDB.Connection, opts)
  end

  def child_spec(opts \\ [])

  @spec child_spec(String.t()) :: Supervisor.child_spec()
  def child_spec(dsn) when is_binary(dsn) do
    opts = Config.connect_opts(dsn: dsn)
    DBConnection.child_spec(EdgeDB.Connection, opts)
  end

  @spec child_spec(list(start_option())) :: Supervisor.child_spec()
  def child_spec(opts) do
    opts = Config.connect_opts(opts)
    DBConnection.child_spec(EdgeDB.Connection, opts)
  end

  @spec child_spec(String.t(), list(start_option())) :: Supervisor.child_spec()
  def child_spec(dsn, opts) do
    opts =
      opts
      |> Keyword.put(:dsn, dsn)
      |> Config.connect_opts()

    DBConnection.child_spec(EdgeDB.Connection, opts)
  end

  @spec query(connection(), String.t(), list() | Keyword.t(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query(conn, statement, params \\ [], opts \\ []) do
    q = %EdgeDB.Query{
      statement: statement,
      cardinality: Keyword.get(opts, :cardinality, :many),
      io_format: Keyword.get(opts, :io_format, :binary),
      required: Keyword.get(opts, :required, false),
      params: params
    }

    prepare_execute_query(conn, q, q.params, opts)
  end

  @spec query!(connection(), String.t(), list(), list(query_option())) :: result()
  def query!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query(statement, params, opts)
    |> unwrap!()
  end

  @spec query_single(connection(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_single(conn, statement, params \\ [], opts \\ []) do
    query(conn, statement, params, Keyword.merge(opts, cardinality: :at_most_one))
  end

  @spec query_single!(connection(), String.t(), list(), list(query_option())) :: result()
  def query_single!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query_single(statement, params, opts)
    |> unwrap!()
  end

  @spec query_required_single(connection(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_required_single(conn, statement, params \\ [], opts \\ []) do
    query_single(conn, statement, params, Keyword.merge(opts, required: true))
  end

  @spec query_required_single!(connection(), String.t(), list(), list(query_option())) :: result()
  def query_required_single!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query_required_single(statement, params, opts)
    |> unwrap!()
  end

  @spec query_json(connection(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_json(conn, statement, params \\ [], opts \\ []) do
    query(conn, statement, params, Keyword.merge(opts, io_format: :json))
  end

  @spec query_json!(connection(), String.t(), list(), list(query_option())) :: result()
  def query_json!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query_json(statement, params, opts)
    |> unwrap!()
  end

  @spec query_single_json(connection(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_single_json(conn, statement, params \\ [], opts \\ []) do
    query_json(conn, statement, params, Keyword.merge(opts, cardinality: :at_most_one))
  end

  @spec query_single_json!(connection(), String.t(), list(), list(query_option())) :: result()
  def query_single_json!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query_single_json(statement, params, opts)
    |> unwrap!()
  end

  @spec query_required_single_json(connection(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_required_single_json(conn, statement, params \\ [], opts \\ []) do
    query_single_json(conn, statement, params, Keyword.merge(opts, required: true))
  end

  @spec query_required_single_json!(connection(), String.t(), list(), list(query_option())) ::
          result()
  def query_required_single_json!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query_required_single_json(statement, params, opts)
    |> unwrap!()
  end

  @spec transaction(
          connection(),
          (DBConnection.t() -> result()),
          list(transaction_option())
        ) ::
          {:ok, result()}
          | {:error, term()}

  def transaction(conn, callback, opts \\ [])

  def transaction(%EdgeDB.WrappedConnection{} = conn, callback, opts) do
    execute_wrapped_callbacks(conn, &transaction(&1, callback, opts))
  end

  def transaction(conn, callback, opts) do
    EdgeDB.Borrower.borrow!(conn, :transaction, fn ->
      retrying_transaction(conn, callback, opts)
    end)
  end

  @spec subtransaction(DBConnection.conn(), (DBConnection.t() -> result())) ::
          {:ok, result()} | {:error, term()}

  def subtransaction(%DBConnection{conn_mode: :transaction} = conn, callback) do
    EdgeDB.Borrower.borrow!(conn, :subtransaction, fn ->
      {:ok, subtransaction_pid} =
        DBConnection.start_link(EdgeDB.Subtransaction, conn: conn, backoff_type: :stop)

      try do
        DBConnection.transaction(subtransaction_pid, callback)
      rescue
        exc ->
          Process.unlink(subtransaction_pid)
          Process.exit(subtransaction_pid, :kill)

          reraise exc, __STACKTRACE__
      else
        result ->
          Process.unlink(subtransaction_pid)
          Process.exit(subtransaction_pid, :kill)

          result
      end
    end)
  end

  def subtransaction(_conn, _callback) do
    raise Error.interface_error(
            "EdgeDB.subtransaction/3 can be used only with connection " <>
              "that is already in transaction (check out EdgeDB.transaction/3) " <>
              "or in another subtransaction"
          )
  end

  @spec subtransaction!(DBConnection.conn(), (DBConnection.conn() -> result())) :: result()
  def subtransaction!(conn, callback) do
    case subtransaction(conn, callback) do
      {:ok, result} ->
        result

      {:error, rollback_reason} ->
        rollback(conn, reason: rollback_reason)
    end
  end

  @spec rollback(connection(), list(rollback_option())) :: :ok | no_return()
  def rollback(conn, opts \\ []) do
    reason = opts[:reason] || :rollback

    with true <- opts[:continue],
         {:ok, _query, true} <-
           DBConnection.execute(conn, %InternalRequest{request: :is_subtransaction}, [], []),
         {:ok, _query, _result} <-
           DBConnection.execute(conn, %InternalRequest{request: :rollback}, [], []) do
      :ok
    else
      {:error, exc} ->
        raise exc

      _other ->
        DBConnection.rollback(conn, reason)
    end
  end

  @spec as_readonly(connection(), list(as_readonly_option())) :: connection()
  def as_readonly(conn, _opts \\ []) do
    EdgeDB.WrappedConnection.wrap(conn, fn conn, callback ->
      with {:ok, _query, capabilities} <-
             DBConnection.execute(conn, %InternalRequest{request: :capabilities}, []),
           {:ok, _query, _result} <-
             DBConnection.execute(conn, %InternalRequest{request: :set_capabilities}, %{
               capabilities: [:readonly]
             }) do
        defer(fn -> callback.(conn) end, fn ->
          DBConnection.execute!(conn, %InternalRequest{request: :set_capabilities}, %{
            capabilities: capabilities
          })
        end)
      end
    end)
  end

  @spec with_transaction_options(connection(), list(edgedb_transaction_option())) :: connection()
  def with_transaction_options(conn, opts) do
    EdgeDB.WrappedConnection.wrap(conn, fn conn, callback ->
      with {:ok, _query, transaction_opts} <-
             DBConnection.execute(conn, %InternalRequest{request: :transaction_options}, []),
           {:ok, _query, _result} <-
             DBConnection.execute(conn, %InternalRequest{request: :set_transaction_options}, %{
               options: opts
             }) do
        defer(fn -> callback.(conn) end, fn ->
          DBConnection.execute!(conn, %InternalRequest{request: :set_transaction_options}, %{
            options: transaction_opts
          })
        end)
      end
    end)
  end

  @spec with_retry_options(connection(), list(retry_option())) :: connection()
  def with_retry_options(conn, opts) do
    EdgeDB.WrappedConnection.wrap(conn, fn conn, callback ->
      with {:ok, _query, retry_opts} <-
             DBConnection.execute(conn, %InternalRequest{request: :retry_options}, []),
           {:ok, _query, _result} <-
             DBConnection.execute(conn, %InternalRequest{request: :set_retry_options}, %{
               options: opts
             }) do
        defer(fn -> callback.(conn) end, fn ->
          request = %InternalRequest{request: :set_retry_options}
          DBConnection.execute!(conn, request, %{options: retry_opts}, replace: true)
        end)
      end
    end)
  end

  defp prepare_execute_query(
         %EdgeDB.WrappedConnection{conn: conn, callbacks: callbacks},
         query,
         params,
         opts
       ) do
    prepare_execute_callback = &prepare_execute_query(&1, query, params, opts)

    execution_callback =
      Enum.reduce([prepare_execute_callback | callbacks], fn next, last ->
        &next.(&1, last)
      end)

    execution_callback.(conn)
  end

  defp prepare_execute_query(conn, query, params, opts) do
    EdgeDB.Borrower.ensure_unborrowed!(conn)

    with {:ok, _query, retry_opts} <-
           DBConnection.execute(conn, %InternalRequest{request: :retry_options}, []) do
      retry_opts = Keyword.merge(retry_opts, opts[:retry] || [])
      prepare_execute_query(1, conn, query, params, Keyword.merge(opts, retry: retry_opts))
    end
  end

  defp prepare_execute_query(attempt, conn, query, params, opts) do
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, %EdgeDB.Query{} = q, %EdgeDB.Result{} = r} ->
        handle_query_result(q, r, opts)

      {:error, %Error{} = exc} ->
        maybe_retry_readonly_query(attempt, exc, conn, query, params, opts)

      {:error, exc} ->
        {:error, exc}
    end
  end

  defp handle_query_result(query, result, opts) do
    cond do
      opts[:raw] ->
        {:ok, {query, result}}

      opts[:io_format] == :json ->
        # in result set there will be only a single value

        extracting_result =
          result
          |> Map.put(:cardinality, :at_most_one)
          |> EdgeDB.Result.extract()

        case extracting_result do
          {:ok, nil} ->
            {:ok, "null"}

          other ->
            other
        end

      true ->
        EdgeDB.Result.extract(result)
    end
  end

  # queries in transaction should be retried using EdgeDB.transaction/3
  defp maybe_retry_readonly_query(
         _attempt,
         exc,
         %DBConnection{conn_mode: :transaction},
         _query,
         _params,
         _opts
       ) do
    {:error, exc}
  end

  defp maybe_retry_readonly_query(
         attempt,
         %Error{query: %EdgeDB.Query{capabilities: capabilities}} = exc,
         conn,
         query,
         params,
         opts
       ) do
    with true <- :readonly in capabilities,
         {:ok, backoff} <- retry?(exc, attempt, opts[:retry] || []) do
      Process.sleep(backoff)
      prepare_execute_query(attempt + 1, conn, query, params, opts)
    else
      _other ->
        {:error, exc}
    end
  end

  defp maybe_retry_readonly_query(_attempt, exc, _conn, _query, _params, _opts) do
    {:error, exc}
  end

  defp retrying_transaction(conn, callback, opts) do
    with {:ok, _query, retry_opts} <-
           DBConnection.execute(conn, %InternalRequest{request: :retry_options}, []) do
      retrying_transaction(1, conn, callback, Keyword.merge(retry_opts, opts[:retry] || []))
    end
  end

  defp retrying_transaction(attempt, conn, callback, retry_opts) do
    DBConnection.transaction(conn, callback, retry_opts)
  rescue
    exc in Error ->
      case retry?(exc, attempt, retry_opts) do
        {:ok, backoff} ->
          Process.sleep(backoff)
          retrying_transaction(attempt + 1, conn, callback, retry_opts)

        :abort ->
          reraise exc, __STACKTRACE__
      end

    exc ->
      reraise exc, __STACKTRACE__
  end

  defp retry?(exception, attempt, retry_opts) do
    rule = rule_for_retry(exception, retry_opts)

    if Error.retry?(exception) and attempt <= rule[:attempts] do
      {:ok, rule[:backoff].(attempt)}
    else
      :abort
    end
  end

  defp rule_for_retry(%Error{} = exception, retry_opts) do
    transaction_conflict_error_code = Error.transaction_conflict_error("").code
    client_error_code = Error.client_error("").code

    rule =
      cond do
        Bitwise.band(transaction_conflict_error_code, exception.code) ==
            transaction_conflict_error_code ->
          Keyword.get(retry_opts, :transaction_conflict, [])

        Bitwise.band(client_error_code, exception.code) == client_error_code ->
          Keyword.get(retry_opts, :network_error, [])

        true ->
          []
      end

    default_rule = [
      attempts: 3,
      backoff: &default_backoff/1
    ]

    Keyword.merge(default_rule, rule)
  end

  defp execute_wrapped_callbacks(
         %EdgeDB.WrappedConnection{conn: conn, callbacks: callbacks},
         callback
       ) do
    DBConnection.run(conn, fn conn ->
      Enum.reduce([callback | callbacks], fn next, last ->
        &next.(&1, last)
      end).(conn)
    end)
  end

  defp defer(original_callback, deferred_callback) do
    original_callback.()
  rescue
    exc ->
      deferred_callback.()
      reraise exc, __STACKTRACE__
  else
    result ->
      deferred_callback.()
      result
  end

  defp default_backoff(attempt) do
    trunc(:math.pow(2, attempt) * Enum.random(0..100))
  end

  defp unwrap!(result) do
    case result do
      {:ok, value} ->
        value

      {:error, exc} ->
        raise exc
    end
  end
end
