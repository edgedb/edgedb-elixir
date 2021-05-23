defmodule EdgeDB.Protocol.Messages.Client.ClientHandshake do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defmessage(
    name: :client_handshake,
    client: true,
    mtype: 0x56,
    fields: [
      major_ver: DataTypes.UInt16.t(),
      minor_ver: DataTypes.UInt16.t(),
      params: [Types.ConnectionParam.t()],
      extensions: [Types.ProtocolExtension.t()]
    ]
  )

  @spec encode_message(t()) :: iodata()
  defp encode_message(
         client_handshake(
           major_ver: major_ver,
           minor_ver: minor_ver,
           params: params,
           extensions: extensions
         )
       ) do
    [
      DataTypes.UInt16.encode(major_ver),
      DataTypes.UInt16.encode(minor_ver),
      Types.ConnectionParam.encode(params),
      Types.ProtocolExtension.encode(extensions)
    ]
  end
end
