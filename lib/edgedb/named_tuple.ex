defmodule EdgeDB.NamedTuple do
  @behaviour Access

  alias EdgeDB.Protocol.Error

  defstruct [
    :__keys__,
    :__values__
  ]

  @opaque named_tuple() :: %__MODULE__{
            __keys__: list(String.t()),
            __values__: tuple()
          }
  @type t() :: %__MODULE__{}

  @spec to_tuple(named_tuple()) :: tuple()
  def to_tuple(%__MODULE__{__values__: values}) do
    values
  end

  @spec keys(named_tuple()) :: list(String.t())
  def keys(%__MODULE__{__keys__: keys}) do
    keys
  end

  @impl Access
  def fetch(%__MODULE__{__values__: values}, index) when is_integer(index) do
    {:ok, elem(values, index)}
  rescue
    ArgumentError ->
      :error
  end

  @impl Access
  def fetch(%__MODULE__{} = tuple, key) when is_atom(key) do
    fetch(tuple, Atom.to_string(key))
  end

  @impl Access
  def fetch(%__MODULE__{__keys__: keys} = tuple, key) when is_binary(key) do
    case Enum.find_index(keys, &(&1 == key)) do
      nil ->
        :error

      idx ->
        fetch(tuple, idx)
    end
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
