defmodule EdgeDB do
  @type connection :: pid()

  @spec start_link(list()) :: DBConnection.start_link()
  def start_link(opts) do
    DBConnection.start_link(EdgeDB.Connection, opts)
  end

  @spec query(connection(), String.t(), list(), list()) :: {:ok, term()} | {:error, Exception.t()}
  def query(conn, statement, params \\ [], opts \\ []) do
    q = %EdgeDB.Query{
      statement: statement
    }

    prepare_execute_query(conn, q, params, opts)
  end

  @spec query_one(connection(), String.t(), list(), list()) ::
          {:ok, term()} | {:error, Exception.t()}
  def query_one(conn, statement, params \\ [], opts \\ []) do
    q = %EdgeDB.Query{
      statement: statement,
      cardinality: :one
    }

    prepare_execute_query(conn, q, params, opts)
  end

  @spec prepare_execute_query(connection(), EdgeDB.Query.t(), list(), list()) ::
          {:ok, term()} | {:error, Exception.t()}
  defp prepare_execute_query(conn, query, params, opts) do
    with {:ok, _q, %EdgeDB.Result{} = r} <-
           DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, EdgeDB.Result.extract(r)}
    end
  end
end
