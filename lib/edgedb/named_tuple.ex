defmodule EdgeDB.NamedTuple do
  @behaviour Access

  alias EdgeDB.Protocol.Errors

  defstruct __keys__: [],
            __values__: []

  @type t() :: %__MODULE__{}

  @spec new(Map.t()) :: t()
  def new(items) do
    new(Map.keys(items), Map.values(items))
  end

  @spec new(list(), list()) :: t()
  def new(keys, values) do
    %__MODULE__{__keys__: keys, __values__: values}
  end

  @spec to_tuple(t()) :: tuple()
  def to_tuple(%__MODULE__{__values__: values}) do
    List.to_tuple(values)
  end

  @spec keys(t()) :: list()
  def keys(%__MODULE__{__keys__: keys}) do
    keys
  end

  @impl Access

  def fetch(%__MODULE__{__values__: values}, index) when is_integer(index) do
    case Enum.at(values, index) do
      nil ->
        :error

      value ->
        {:ok, value}
    end
  end

  def fetch(%__MODULE__{} = tuple, key) when is_atom(key) do
    fetch(tuple, Atom.to_string(key))
  end

  def fetch(%__MODULE__{__keys__: keys} = tuple, key) do
    case Enum.find_index(keys, key) do
      nil ->
        :error

      idx ->
        fetch(tuple, idx)
    end
  end

  @impl Access
  def get_and_update(%__MODULE__{}, _key, _function) do
    raise Errors.InterfaceError, "named tuples can't be mutated"
  end

  @impl Access
  def pop(%__MODULE__{}, _key) do
    raise Errors.InterfaceError, "named tuples can't be mutated"
  end
end

defimpl Enumerable, for: EdgeDB.NamedTuple do
  @impl Enumerable
  def count(%EdgeDB.NamedTuple{__values__: values}) do
    Enumerable.count(values)
  end

  @impl Enumerable
  def member?(%EdgeDB.NamedTuple{__values__: values}, element) do
    Enumerable.member?(values, element)
  end

  @impl Enumerable
  def reduce(%EdgeDB.NamedTuple{__values__: values}, acc, fun) do
    Enumerable.reduce(values, acc, fun)
  end

  @impl Enumerable
  def slice(%EdgeDB.NamedTuple{__values__: values}) do
    Enumerable.slice(values)
  end
end
