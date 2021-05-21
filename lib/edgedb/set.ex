defmodule EdgeDB.Set do
  defstruct [:__items__]

  @type t() :: term()

  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{__items__: items}) do
    MapSet.size(items) == 0
  end

  @spec new() :: t()
  def new do
    %EdgeDB.Set{__items__: MapSet.new()}
  end

  @spec new(Enumerable.t()) :: t()
  def new(elements) do
    %EdgeDB.Set{__items__: MapSet.new(elements)}
  end

  @spec add(t(), any()) :: t()
  def add(%EdgeDB.Set{__items__: items} = set, value) do
    %EdgeDB.Set{set | __items__: MapSet.put(items, value)}
  end
end

defimpl Enumerable, for: EdgeDB.Set do
  @impl Enumerable
  def count(%EdgeDB.Set{__items__: items}) do
    Enumerable.count(items)
  end

  @impl Enumerable
  def member?(%EdgeDB.Set{__items__: items}, element) do
    Enumerable.member?(items, element)
  end

  @impl Enumerable
  def reduce(%EdgeDB.Set{__items__: items}, acc, fun) do
    Enumerable.reduce(items, acc, fun)
  end

  @impl Enumerable
  def slice(%EdgeDB.Set{__items__: items}) do
    Enumerable.slice(items)
  end
end
