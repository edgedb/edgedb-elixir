defmodule EdgeDB.Set do
  defstruct [:__items__]

  @type t() :: term()

  def empty?(%__MODULE__{__items__: items}) do
    MapSet.size(items) == 0
  end

  def _new do
    %EdgeDB.Set{__items__: MapSet.new()}
  end

  def _new(elements) do
    %EdgeDB.Set{__items__: MapSet.new(elements)}
  end

  def _add(%EdgeDB.Set{__items__: items} = set, value) do
    %EdgeDB.Set{set | __items__: MapSet.put(items, value)}
  end
end

defimpl Enumerable, for: EdgeDB.Set do
  def count(%EdgeDB.Set{__items__: items}) do
    Enumerable.count(items)
  end

  def member?(%EdgeDB.Set{__items__: items}, element) do
    Enumerable.member?(items, element)
  end

  def reduce(%EdgeDB.Set{__items__: items}, acc, fun) do
    Enumerable.reduce(items, acc, fun)
  end

  def slice(%EdgeDB.Set{__items__: items}) do
    Enumerable.slice(items)
  end
end
