defmodule EdgeDB.Set do
  @moduledoc """
  A representation of an immutable set of values returned by a query.
    Nested sets in the result are also returned as `EdgeDB.Set` objects.

  `EdgeDB.Set` implements `Enumerable` protocol for iterating over set values.

  ```elixir
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> %EdgeDB.Set{} =
  iex(2)>  EdgeDB.query!(client, "\"\"
  ...(2)>   select schema::ObjectType{
  ...(2)>     name
  ...(2)>   }
  ...(2)>   filter .name IN {'std::BaseObject', 'std::Object', 'std::FreeObject'}
  ...(2)>   order by .name
  ...(2)>  \"\"")
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
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> %EdgeDB.Set{} = set = EdgeDB.query!(client, "select Ticket")
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
  def member?(%EdgeDB.Set{__items__: []}, _element) do
    {:ok, false}
  end

  @impl Enumerable
  def member?(%EdgeDB.Set{}, _element) do
    {:error, __MODULE__}
  end

  @impl Enumerable
  def slice(%EdgeDB.Set{__items__: []}) do
    {:ok, 0, fn _start, _amount, _step -> [] end}
  end

  @impl Enumerable
  def slice(%EdgeDB.Set{}) do
    {:error, __MODULE__}
  end

  @impl Enumerable
  def reduce(%EdgeDB.Set{}, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  @impl Enumerable
  def reduce(%EdgeDB.Set{} = set, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce(set, &1, fun)}
  end

  @impl Enumerable
  def reduce(%EdgeDB.Set{__items__: []}, {:cont, acc}, _fun) do
    {:done, acc}
  end

  @impl Enumerable
  def reduce(%EdgeDB.Set{__items__: [item | items]}, {:cont, acc}, fun) do
    reduce(%EdgeDB.Set{__items__: items}, fun.(item, acc), fun)
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
