defmodule EdgeDB.Protocol.Types.ConnectionParam do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  deftype(
    decode?: false,
    name: :connection_param,
    fields: [
      name: DataTypes.String.t(),
      value: DataTypes.String.t()
    ]
  )

  @spec encode(t()) :: bitstring()
  def encode(connection_param(name: name, value: value)) do
    [DataTypes.String.encode(name), DataTypes.String.encode(value)]
  end
end
