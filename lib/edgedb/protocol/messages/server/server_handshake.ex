defmodule EdgeDB.Protocol.Messages.Server.ServerHandshake do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Types

  defmessage(
    server: true,
    mtype: 0x76,
    name: :server_handshake,
    fields: [
      extensions: [Types.ProtocolExtension.t()]
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(
         <<_major_ver::uint16, _minor_ver::uint16, num_extensions::uint16, rest::binary>>
       ) do
    {extensions, <<>>} = Types.ProtocolExtension.decode(num_extensions, rest)
    server_handshake(extensions: extensions)
  end
end
