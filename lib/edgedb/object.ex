defmodule EdgeDB.Object do
  @behaviour Access

  alias EdgeDB.Protocol.{
    Datatypes,
    Error
  }

  defmodule Field do
    defstruct [
      :name,
      :value,
      :link?,
      :link_property?,
      :implicit?
    ]

    @type t() :: %__MODULE__{
            name: String.t(),
            value: any(),
            link?: boolean(),
            link_property?: boolean(),
            implicit?: boolean()
          }
  end

  defstruct [
    :__fields__,
    :__tid__,
    :id
  ]

  @type t() :: %__MODULE__{
          __fields__: list(Field.t()),
          __tid__: Datatypes.UUID.t() | nil,
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
    raise Error.interface_error("objects can't be mutated")
  end

  @impl Access
  def pop(%__MODULE__{}, _key) do
    raise Error.interface_error("objects can't be mutated")
  end

  @spec from_fields(list(Field.t())) :: t()
  def from_fields(fields) do
    id =
      case find_field(fields, "id") do
        nil ->
          nil

        field ->
          field.value
      end

    type_id =
      case find_field(fields, "__tid__") do
        nil ->
          nil

        field ->
          field.value
      end

    %__MODULE__{
      id: id,
      __tid__: type_id,
      __fields__: fields
    }
  end

  @spec find_field(list(Field.t()), String.t()) :: Field.t() | nil
  defp find_field(fields, name_to_find) do
    Enum.find(fields, fn %{name: name} ->
      name == name_to_find
    end)
  end
end
