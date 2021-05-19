defmodule EdgeDB.Protocol.Messages.Server.ServerKeyData do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  @key_data_length 32

  defmessage(
    server: true,
    mtype: 0x4B,
    name: :server_key_data,
    fields: [
      data: [DataTypes.UInt8]
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<rest::binary>>) do
    {data, <<>>} = DataTypes.UInt8.decode(@key_data_length, rest)
    server_key_data(data: data)
  end
end
