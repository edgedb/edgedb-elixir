defmodule EdgeDB.Set do
  @moduledoc """
  A representation of an immutable set of values returned by a query.
    Nested sets in the result are also returned as `EdgeDB.Set` objects.

  `EdgeDB.Set` implements `Enumerable` protocol for iterating over set values.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> %EdgeDB.Set{} =
  iex(2)>  EdgeDB.query!(pid, "
  ...(2)>   select schema::ObjectType{
  ...(2)>     name
  ...(2)>   }
  ...(2)>   filter .name IN {'std::BaseObject', 'std::Object', 'std::FreeObject'}
  ...(2)>   order by .name
  ...(2)>  ")
  #EdgeDB.Set<{#EdgeDB.Object<name := "std::BaseObject">, #EdgeDB.Object<name := "std::FreeObject">, #EdgeDB.Object<name := "std::Object">}>
  ```
  """

  defstruct [
    :__items__
  ]

  @typedoc """
  A representation of an immutable set of values returned by a query.
  """
  @opaque t() :: %__MODULE__{}

  @doc """
  Check if set is empty.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> %EdgeDB.Set{} = set = EdgeDB.query!(pid, "select Ticket")
  iex(3)> EdgeDB.Set.empty?(set)
  true
  ```
  """
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
