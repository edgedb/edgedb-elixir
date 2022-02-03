defmodule EdgeDB.Set do
  defstruct [
    :__items__
  ]

  @opaque set() :: %__MODULE__{
            __items__: MapSet.t()
          }
  @type t() :: %__MODULE__{}

  @spec empty?(t()) :: boolean()

  def empty?(%__MODULE__{__items__: []}) do
    true
  end

  def empty?(%__MODULE__{}) do
    false
  end
end

defimpl Enumerable, for: EdgeDB.Set do
  @impl Enumerable
  def count(%EdgeDB.Set{__items__: items}) do
    {:ok, length(items)}
  end

  @impl Enumerable
  def member?(%EdgeDB.Set{__items__: items}, element) do
    {:ok, Enum.member?(items, element)}
  end

  @impl Enumerable
  def reduce(%EdgeDB.Set{__items__: items}, acc, fun) do
    Enumerable.List.reduce(items, acc, fun)
  end

  @impl Enumerable
  def slice(%EdgeDB.Set{__items__: items}) do
    set_length = length(items)
    {:ok, set_length, &Enumerable.List.slice(items, &1, &2, set_length)}
  end
end

defimpl Inspect, for: EdgeDB.Set do
  import Inspect.Algebra

  @impl Inspect
  def inspect(%EdgeDB.Set{} = set, opts) do
    elements = Enum.to_list(set)

    element_fn = fn element, opts ->
      Inspect.inspect(element, opts)
    end

    concat(["#EdgeDB.Set<", container_doc("{", elements, "}", opts, element_fn), ">"])
  end
end
