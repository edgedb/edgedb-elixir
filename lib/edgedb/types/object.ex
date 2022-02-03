defmodule EdgeDB.Object do
  @behaviour Access

  alias EdgeDB.Object.Field
  alias EdgeDB.Protocol.Datatypes

  defstruct [
    :__fields__,
    :__tid__,
    :id
  ]

  @opaque object() :: %__MODULE__{
            __fields__: list(Field.t()),
            __tid__: Datatypes.UUID.t() | nil,
            id: Datatypes.UUID.t() | nil
          }
  @type t() :: %__MODULE__{
          id: Datatypes.UUID.t() | nil
        }

  @impl Access
  def fetch(%__MODULE__{} = object, key) when is_atom(key) do
    fetch(object, Atom.to_string(key))
  end

  @impl Access
  def fetch(%__MODULE__{__fields__: fields}, key) do
    case find_field(fields, key) do
      nil ->
        :error

      field ->
        {:ok, field.value}
    end
  end

  @impl Access
  def get_and_update(%__MODULE__{}, _key, _function) do
    raise EdgeDB.Error.interface_error("objects can't be mutated")
  end

  @impl Access
  def pop(%__MODULE__{}, _key) do
    raise EdgeDB.Error.interface_error("objects can't be mutated")
  end

  defp find_field(fields, name_to_find) do
    Enum.find(fields, fn %{name: name} ->
      name == name_to_find
    end)
  end
end

defimpl Inspect, for: EdgeDB.Object do
  import Inspect.Algebra

  @impl Inspect
  def inspect(%EdgeDB.Object{__fields__: fields}, opts) do
    visible_fields =
      Enum.reject(fields, fn %EdgeDB.Object.Field{is_implicit: implicit?} ->
        implicit?
      end)

    fields_count = Enum.count(visible_fields)

    elements_docs =
      visible_fields
      |> Enum.with_index(1)
      |> Enum.map(fn
        {%EdgeDB.Object.Field{name: name, value: value}, ^fields_count} ->
          concat([name, " := ", Inspect.inspect(value, opts)])

        {%EdgeDB.Object.Field{name: name, value: value}, _index} ->
          concat([name, " := ", Inspect.inspect(value, opts), ", "])
      end)

    concat(["#EdgeDB.Object<", concat(elements_docs), ">"])
  end
end
