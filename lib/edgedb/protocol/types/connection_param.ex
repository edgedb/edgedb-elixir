defmodule EdgeDB.Protocol.Types.ConnectionParam do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  deftype(
    name: :connection_param,
    decode?: false,
    fields: [
      name: DataTypes.String.t(),
      value: DataTypes.String.t()
    ]
  )

  @spec encode(t()) :: iodata()
  def encode(connection_param(name: name, value: value)) do
    [DataTypes.String.encode(name), DataTypes.String.encode(value)]
  end
end
