defmodule EdgeDB.Protocol.Messages.Server.ServerHandshake do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defmessage(
    name: :server_handshake,
    server: true,
    mtype: 0x76,
    fields: [
      major_ver: DataTypes.UInt16.t(),
      minor_ver: DataTypes.UInt16.t(),
      extensions: [Types.ProtocolExtension.t()]
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(
         <<major_ver::uint16, minor_ver::uint16, num_extensions::uint16, rest::binary>>
       ) do
    {extensions, <<>>} = Types.ProtocolExtension.decode(num_extensions, rest)

    server_handshake(
      major_ver: major_ver,
      minor_ver: minor_ver,
      extensions: extensions
    )
  end
end
