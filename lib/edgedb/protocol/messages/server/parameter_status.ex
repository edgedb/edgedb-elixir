defmodule EdgeDB.Protocol.Messages.Server.ParameterStatus do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  defmessage(
    name: :parameter_status,
    server: true,
    mtype: 0x53,
    fields: [
      name: DataTypes.Bytes.t(),
      value: DataTypes.Bytes.t()
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<rest::binary>>) do
    {name, rest} = DataTypes.Bytes.decode(rest)
    {value, <<>>} = DataTypes.Bytes.decode(rest)
    parameter_status(name: name, value: value)
  end
end
