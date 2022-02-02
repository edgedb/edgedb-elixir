defmodule EdgeDB.Connection.QueriesCache do
  @moduledoc false

  use GenServer

  alias EdgeDB.Protocol.Enums

  defmodule State do
    @moduledoc false

    defstruct [
      :cache
    ]

    @type t() :: %__MODULE__{
            cache: :ets.tab()
          }
  end

  @type t() :: GenServer.server()

  @spec start_link(list()) :: GenServer.on_start()
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [])
  end

  @spec get(t(), String.t(), Enums.Cardinality.t(), Enums.IOFormat.t(), boolean()) ::
          EdgeDB.Query.t() | nil
  def get(cache, statement, cardinality, io_format, required) do
    GenServer.call(cache, {:get, statement, cardinality, io_format, required})
  end

  @spec add(t(), EdgeDB.Query.t()) :: :ok
  def add(cache, %EdgeDB.Query{} = query) do
    GenServer.cast(cache, {:add, query})
  end

  @spec clear(t(), EdgeDB.Query.t()) :: :ok
  def clear(cache, %EdgeDB.Query{} = query) do
    GenServer.cast(cache, {:clear, query})
  end

  @impl GenServer
  def init(_opts \\ []) do
    {:ok, %State{cache: new_cache()}}
  end

  @impl GenServer
  def handle_call(
        {:get, statement, cardinality, io_format, required},
        _from,
        %State{cache: cache} = state
      ) do
    key = {statement, cardinality, io_format, required}

    query =
      case :ets.lookup(cache, key) do
        [{^key, query}] ->
          query

        [] ->
          nil
      end

    {:reply, query, state}
  end

  @impl GenServer
  def handle_cast({:add, query}, %State{cache: cache} = state) do
    key = {query.statement, query.cardinality, query.io_format, query.required}
    :ets.insert(cache, {key, %EdgeDB.Query{query | cached: true}})

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:clear, query}, %State{cache: cache} = state) do
    key = {query.statement, query.cardinality, query.io_format, query.required}
    :ets.delete(cache, key)

    {:noreply, state}
  end

  defp new_cache do
    :ets.new(:connection_queries_cache, [:set, :private])
  end
end
