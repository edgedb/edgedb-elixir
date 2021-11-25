defmodule EdgeDB do
  alias EdgeDB.Connection.{
    Config,
    InternalRequest
  }

  alias EdgeDB.Protocol.Enums

  @type connection() :: DBConnection.conn() | EdgeDB.WrappedConnection.t()
  @type tls_security() :: :insecure | :no_host_verification | :strict | :default

  # NOTE: :command_timeout, :wait_for_available and :server_settings
  # options added only for compatability with other drivers and aren't used right now
  @type connect_option() ::
          {:dsn, String.t()}
          | {:credentials_file, Path.t()}
          | {:host, String.t()}
          | {:port, :inet.port_number()}
          | {:database, String.t()}
          | {:user, String.t()}
          | {:password, String.t()}
          | {:tls_ca_file, Path.t()}
          | {:tls_security, tls_security()}
          | {:timeout, timeout()}
          | {:command_timeout, timeout()}
          | {:wait_for_available, integer()}
          | {:server_settings, map()}
          | {:tcp, list(:gen_tcp.option())}
          | {:ssl, list(:ssl.tls_client_option())}

  @type start_option() ::
          connect_option()
          | DBConnection.start_option()

  @type query_option() ::
          {:cardinality, Enums.Cardinality.t()}
          | {:io_format, Enums.IOFormat.t()}
          | DBConnection.option()

  @type transaction_option() :: DBConnection.option()

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

  @spec transaction(connection(), (DBConnection.t() -> result()), list(transaction_option())) ::
          {:ok, result()}
          | {:error, term()}

  def transaction(conn, callback, opts \\ [])

  def transaction(%EdgeDB.WrappedConnection{conn: conn, callbacks: callbacks}, callback, opts) do
    transaction_callback = &transaction(&1, callback, opts)

    execution_callback =
      Enum.reduce([transaction_callback | callbacks], fn next, last ->
        &next.(&1, last)
      end)

    execution_callback.(conn)
  end

  def transaction(conn, callback, opts) do
    DBConnection.transaction(conn, callback, opts)
  end

  @spec rollback(connection(), term()) :: no_return()
  def rollback(conn, reason) do
    DBConnection.rollback(conn, reason)
  end

  @spec as_readonly(connection(), list(as_readonly_option())) :: connection()
  def as_readonly(conn, _opts \\ []) do
    EdgeDB.WrappedConnection.wrap(conn, fn conn, callback ->
      request = %InternalRequest{request: :capabilities}
      capabilities = DBConnection.execute!(conn, request, [], [])

      request = %InternalRequest{request: :set_capabilities}
      DBConnection.execute!(conn, request, %{capabilities: [:readonly]}, [])

      result = callback.(conn)

      request = %InternalRequest{request: :set_capabilities}
      DBConnection.execute!(conn, request, %{capabilities: capabilities}, [])

      result
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
    with {:ok, %EdgeDB.Query{} = q, %EdgeDB.Result{} = r} <-
           DBConnection.prepare_execute(conn, query, params, opts) do
      cond do
        opts[:raw] ->
          {:ok, {q, r}}

        opts[:io_format] == :json ->
          # in result set there will be only a single value

          result =
            r
            |> Map.put(:cardinality, :at_most_one)
            |> EdgeDB.Result.extract()

          case result do
            {:ok, nil} ->
              {:ok, "null"}

            other ->
              other
          end

        true ->
          EdgeDB.Result.extract(r)
      end
    end
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
