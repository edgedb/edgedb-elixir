defmodule EdgeDB do
  alias EdgeDB.Protocol.Enums

  @type connection() :: DBConnection.conn()

  @type connect_option() ::
          {:host, String.t()}
          | {:port, :inet.port_number()}
          | {:user, String.t()}
          | {:database, String.t()}
          | {:password, String.t()}

  @type start_option() ::
          connect_option()
          | DBConnection.start_option()
  @type start_options() :: list(start_option())

  @type query_option() ::
          {:cardinality, Enums.Cardinality.t()}
          | {:io_format, Enums.IOFormat.t()}
          | DBConnection.option()
  @type query_options() :: list(query_option())

  @type transaction_option() :: DBConnection.option()
  @type transaction_options() :: list(transaction_option())

  @type raw_result() :: {EdgeDB.Query.t(), EdgeDB.Result.t()}
  @type result() :: EdgeDB.Set.t() | term() | raw_result()

  @spec start_link(start_options()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    opts = EdgeDB.Config.connect_opts(opts)
    DBConnection.start_link(EdgeDB.Connection, opts)
  end

  @spec child_spec(start_options()) :: Supervisor.child_spec()
  def child_spec(opts) do
    opts = EdgeDB.Config.connect_opts(opts)
    DBConnection.child_spec(EdgeDB.Connection, opts)
  end

  @spec query(connection(), String.t(), list(), query_options()) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query(conn, statement, params \\ [], opts \\ []) do
    q = %EdgeDB.Query{
      statement: statement,
      cardinality: Keyword.get(opts, :cardinality, :many),
      io_format: Keyword.get(opts, :io_format, :binary),
      params: params
    }

    prepare_execute_query(conn, q, q.params, opts)
  end

  @spec query!(connection(), String.t(), list(), query_options()) :: result()
  def query!(conn, statement, params \\ [], opts \\ []) do
    case query(conn, statement, params, opts) do
      {:ok, result} ->
        result

      {:error, exc} ->
        raise exc
    end
  end

  @spec query_json(connection(), String.t(), list(), query_options()) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_json(conn, statement, params \\ [], opts \\ []) do
    query(conn, statement, params, Keyword.merge(opts, io_format: :json))
  end

  @spec query_json!(connection(), String.t(), list(), query_options()) :: result()
  def query_json!(conn, statement, params \\ [], opts \\ []) do
    query!(conn, statement, params, Keyword.merge(opts, io_format: :json))
  end

  @spec query_single(connection(), String.t(), list(), query_options()) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_single(conn, statement, params \\ [], opts \\ []) do
    query(conn, statement, params, Keyword.merge(opts, cardinality: :at_most_one))
  end

  @spec query_single!(connection(), String.t(), list(), query_options()) :: result()
  def query_single!(conn, statement, params \\ [], opts \\ []) do
    case query_single(conn, statement, params, opts) do
      {:ok, result} ->
        result

      {:error, exc} ->
        raise exc
    end
  end

  @spec query_single_json(connection(), String.t(), list(), query_options()) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_single_json(conn, statement, params \\ [], opts \\ []) do
    query_json(
      conn,
      statement,
      params,
      Keyword.merge(opts, cardinality: :at_most_one)
    )
  end

  @spec query_single_json!(connection(), String.t(), list(), query_options()) :: result()
  def query_single_json!(conn, statement, params \\ [], opts \\ []) do
    query_json!(
      conn,
      statement,
      params,
      Keyword.merge(opts, cardinality: :at_most_one)
    )
  end

  @spec transaction(connection(), (DBConnection.t() -> result()), transaction_options()) ::
          {:ok, result()}
          | {:error, term()}
  def transaction(conn, callback, opts \\ []) do
    DBConnection.transaction(conn, callback, opts)
  end

  @spec rollback(connection(), term()) :: no_return()
  def rollback(conn, reason) do
    DBConnection.rollback(conn, reason)
  end

  defp prepare_execute_query(conn, query, params, opts) do
    with {:ok, %EdgeDB.Query{} = q, %EdgeDB.Result{} = r} <-
           DBConnection.prepare_execute(conn, query, params, opts) do
      result =
        cond do
          opts[:raw] ->
            {q, r}

          opts[:io_format] == :json ->
            # in result set there will be only a single value

            r
            |> Map.put(:cardinality, :at_most_one)
            |> EdgeDB.Result.extract()

          true ->
            EdgeDB.Result.extract(r)
        end

      {:ok, result}
    end
  end
end
