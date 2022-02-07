defmodule EdgeDB.Protocol.Types.ConnectionParam do
  @moduledoc false

  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  deftype(
    decode: false,
    fields: [
      name: Datatypes.String.t(),
      value: Datatypes.String.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def encode_type(%__MODULE__{name: name, value: value}) do
    [Datatypes.String.encode(name), Datatypes.String.encode(value)]
  end
end
