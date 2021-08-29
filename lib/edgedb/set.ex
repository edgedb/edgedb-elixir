defmodule EdgeDB.Set do
  defstruct [
    :__items__
  ]

  @opaque set() :: %__MODULE__{
            __items__: MapSet.t()
          }
  @type t() :: %__MODULE__{}

  @spec empty?(set()) :: boolean()
  def empty?(%__MODULE__{__items__: items}) do
    MapSet.size(items) == 0
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
