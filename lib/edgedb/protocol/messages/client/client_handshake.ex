defmodule EdgeDB.Protocol.Messages.Client.ClientHandshake do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  defmessage(
    name: :client_handshake,
    client: true,
    mtype: 0x56,
    fields: [
      major_ver: Datatypes.UInt16.t(),
      minor_ver: Datatypes.UInt16.t(),
      params: list(Types.ConnectionParam.t()),
      extensions: list(Types.ProtocolExtension.t())
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(
        client_handshake(
          major_ver: major_ver,
          minor_ver: minor_ver,
          params: params,
          extensions: extensions
        )
      ) do
    [
      Datatypes.UInt16.encode(major_ver),
      Datatypes.UInt16.encode(minor_ver),
      Types.ConnectionParam.encode(params),
      Types.ProtocolExtension.encode(extensions)
    ]
  end
end
