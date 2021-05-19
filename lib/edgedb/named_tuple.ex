defmodule EdgeDB.NamedTuple do
  # TODO: implement Access behaviour

  defstruct [:__items__]

  @type t() :: %__MODULE__{}

  def new do
    %__MODULE__{__items__: %{}}
  end

  def new(items) do
    %__MODULE__{__items__: Enum.into(items, %{})}
  end
end
