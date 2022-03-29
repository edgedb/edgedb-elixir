defmodule EdgeDB.Connection.QueriesCache do
  @moduledoc false

  alias EdgeDB.Protocol.Enums

  @type t() :: :ets.tab()

  @spec new() :: t()
  def new do
    :ets.new(:connection_queries_cache, [:set, :public, {:read_concurrency, true}])
  end

  @spec get(t(), String.t(), Enums.cardinality(), Enums.io_format(), boolean()) ::
          EdgeDB.Query.t() | nil
  def get(cache, statement, cardinality, io_format, required) do
    key = {statement, cardinality, io_format, required}

    case :ets.lookup(cache, key) do
      [{^key, query}] ->
        query

      [] ->
        nil
    end
  end

  @spec add(t(), EdgeDB.Query.t()) :: :ok
  def add(cache, %EdgeDB.Query{} = query) do
    key = {query.statement, query.cardinality, query.io_format, query.required}
    :ets.insert(cache, {key, %EdgeDB.Query{query | cached: true}})
    :ok
  end

  @spec clear(t(), EdgeDB.Query.t()) :: :ok
  def clear(cache, %EdgeDB.Query{} = query) do
    key = {query.statement, query.cardinality, query.io_format, query.required}
    :ets.delete(cache, key)
    :ok
  end
end
