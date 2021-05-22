defmodule EdgeDB.Object do
  @behaviour Access

  alias EdgeDB.Protocol.Errors

  defstruct [:__fields__, :id, :__tid__]

  @type t() :: %__MODULE__{}

  defmodule Field do
    defstruct [
      :name,
      :value,
      :link?,
      :link_property?,
      :implicit?
    ]

    @type t() :: %__MODULE__{}
  end

  @impl Access

  def fetch(%__MODULE__{} = object, key) when is_atom(key) do
    fetch(object, Atom.to_string(key))
  end

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
    raise Errors.InterfaceError, "objects can't be mutated"
  end

  @impl Access
  def pop(%__MODULE__{}, _key) do
    raise Errors.InterfaceError, "objects can't be mutated"
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

  defp find_field(fields, name_to_find) do
    Enum.find(fields, fn %{name: name} ->
      name == name_to_find
    end)
  end
end
