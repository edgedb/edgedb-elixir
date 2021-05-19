defmodule EdgeDB.Enum do
  # TODO: implement Access behaviour

  defstruct [:__members__, :value]

  @type t() :: %__MODULE__{}

  def _new(members, value) do
    %__MODULE__{__members__: members, value: value}
  end
end
