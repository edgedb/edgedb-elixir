defmodule EdgeDB.Object do
  # TODO: implement Access behaviour

  defstruct [:__fields__, :id, :__tid__]

  @type t() :: %__MODULE__{}

  defmodule Field do
    defstruct [:name, :value, :link?, :link_property?, :implicit?]
  end

  def _from_fields(fields) do
    id = Enum.find(fields, fn %{name: name} -> name == "id" end)
    type_id = Enum.find(fields, fn %{name: name} -> name == "__tid__" end)

    %__MODULE__{
      id: id.value,
      __tid__: type_id.value,
      __fields__: fields
    }
  end
end
