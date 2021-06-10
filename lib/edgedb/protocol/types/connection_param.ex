defmodule EdgeDB.Protocol.Types.ConnectionParam do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  deftype(
    name: :connection_param,
    decode?: false,
    fields: [
      name: Datatypes.String.t(),
      value: Datatypes.String.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def encode_type(connection_param(name: name, value: value)) do
    [Datatypes.String.encode(name), Datatypes.String.encode(value)]
  end
end
