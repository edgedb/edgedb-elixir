defmodule EdgeDB.Connection.QueriesCache do
  use GenServer

  defmodule State do
    defstruct [:cache]
  end

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [])
  end

  def get(cache, statement, cardinality, io_format) do
    GenServer.call(cache, {:get, statement, cardinality, io_format})
  end

  def add(cache, %EdgeDB.Query{} = query) do
    GenServer.cast(cache, {:add, query})
  end

  def clear(cache, %EdgeDB.Query{} = query) do
    GenServer.cast(cache, {:clear, query})
  end

  def init(_opts \\ []) do
    {:ok, %State{cache: new_cache()}}
  end

  def handle_call({:get, statement, cardinality, io_format}, _from, %State{cache: cache} = state) do
    key = {statement, cardinality, io_format}

    query =
      case :ets.lookup(cache, key) do
        [{^key, query}] ->
          query

        [] ->
          nil
      end

    {:reply, query, state}
  end

  def handle_cast({:add, query}, %State{cache: cache} = state) do
    key = {query.statement, query.cardinality, query.io_format}
    :ets.insert(cache, {key, %EdgeDB.Query{query | cached?: true}})

    {:noreply, state}
  end

  def handle_cast({:clear, query}, %State{cache: cache} = state) do
    key = {query.statement, query.cardinality, query.io_format}
    :ets.delete(cache, key)

    {:noreply, state}
  end

  defp new_cache do
    :ets.new(:connection_queries_cache, [:set, :private])
  end
end
