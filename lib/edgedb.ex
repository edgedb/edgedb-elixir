defmodule EdgeDB do
  alias EdgeDB.Protocol.Enums

  @type connection() :: DBConnection.conn()
  @type start_option() ::
          {:host, String.t()}
          | {:port, :inet.port_number()}
          | {:username, String.t()}
          | {:database, String.t()}
          | {:password, String.t()}
          | DBConnection.start_option()
  @type start_options() :: list(start_option())

  @type query_option() ::
          {:cardinality, Enums.Cardinality.t()}
          | DBConnection.option()
  @type query_options() :: list(query_option())

  @type transaction_option() :: DBConnection.option()
  @type transaction_options() :: list(transaction_option())

  @type result() :: EdgeDB.Set.t() | term()

  @spec start_link(start_options()) :: GenServer.on_start()
  def start_link(opts) do
    DBConnection.start_link(EdgeDB.Connection, opts)
  end

  @spec query(connection(), String.t(), list(), query_options()) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query(conn, statement, params \\ [], opts \\ []) do
    q = EdgeDB.Query.new(statement, params, opts)
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

  @spec query_one(connection(), String.t(), list(), query_options()) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_one(conn, statement, params \\ [], opts \\ []) do
    query(conn, statement, params, Keyword.merge(opts, cardinality: :one))
  end

  @spec query_one!(connection(), String.t(), list(), query_options()) :: result()
  def query_one!(conn, statement, params \\ [], opts \\ []) do
    case query_one(conn, statement, params, opts) do
      {:ok, result} ->
        result

      {:error, exc} ->
        raise exc
    end
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

  @spec prepare_execute_query(connection, EdgeDB.Query.t(), list(), query_options()) ::
          {:ok, result()}
          | {:error, Exception.t()}
  defp prepare_execute_query(conn, query, params, opts) do
    with {:ok, _q, %EdgeDB.Result{} = r} <-
           DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, EdgeDB.Result.extract(r)}
    end
  end
end
