defmodule EdgeDB.NamedTuple do
  @behaviour Access

  alias EdgeDB.Protocol.Error

  defstruct [
    :__fields_ordering__,
    :__items__
  ]

  @opaque named_tuple() :: %__MODULE__{
            __fields_ordering__: %{integer() => String.t()},
            __items__: %{String.t() => any()}
          }
  @type t() :: %__MODULE__{}

  @spec to_tuple(named_tuple()) :: tuple()
  def to_tuple(%__MODULE__{__items__: items}) do
    items
    |> Map.values()
    |> List.to_tuple()
  end

  @spec keys(named_tuple()) :: list(String.t())
  def keys(%__MODULE__{__items__: items}) do
    Map.keys(items)
  end

  @impl Access
  def fetch(%__MODULE__{__items__: items, __fields_ordering__: fields_order}, index)
      when is_integer(index) do
    with {:ok, name} <- Map.fetch(fields_order, index) do
      Map.fetch(items, name)
    end
  rescue
    ArgumentError ->
      :error
  end

  @impl Access
  def fetch(%__MODULE__{} = tuple, key) when is_atom(key) do
    fetch(tuple, Atom.to_string(key))
  end

  @impl Access
  def fetch(%__MODULE__{__items__: items}, key) when is_binary(key) do
    Map.fetch(items, key)
  end

  @impl Access
  def get_and_update(%__MODULE__{}, _key, _function) do
    raise Error.interface_error("named tuples can't be mutated")
  end

  @impl Access
  def pop(%__MODULE__{}, _key) do
    raise Error.interface_error("named tuples can't be mutated")
  end
end

defimpl Enumerable, for: EdgeDB.NamedTuple do
  @impl Enumerable
  def count(%EdgeDB.NamedTuple{__items__: items}) do
    Enumerable.count(items)
  end

  @impl Enumerable
  def member?(%EdgeDB.NamedTuple{__items__: items}, element) do
    items
    |> Map.values()
    |> Enumerable.member?(element)
  end

  @impl Enumerable
  def reduce(%EdgeDB.NamedTuple{__items__: items}, acc, fun) do
    items
    |> Map.values()
    |> Enumerable.reduce(acc, fun)
  end

  @impl Enumerable
  def slice(%EdgeDB.NamedTuple{__items__: items}) do
    items
    |> Map.values()
    |> Enumerable.slice()
  end
end

defimpl Inspect, for: EdgeDB.NamedTuple do
  import Inspect.Algebra

  @impl Inspect
  def inspect(%EdgeDB.NamedTuple{__items__: items, __fields_ordering__: fields_order}, _opts) do
    {max_index, _name} =
      Enum.max(fields_order, fn ->
        {nil, nil}
      end)

    elements_docs =
      fields_order
      |> Enum.map(fn {index, name} ->
        {index, glue(name, ": ", inspect(items[name]))}
      end)
      |> Enum.sort()
      |> Enum.map(fn
        {^max_index, doc} ->
          doc

        {_index, doc} ->
          concat(doc, ", ")
      end)

    concat(["#EdgeDB.NamedTuple<", concat(elements_docs), ">"])
  end
end
