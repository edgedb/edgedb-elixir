defmodule EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationOK do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  defmessage(
    name: :authentication_ok,
    server: true,
    mtype: 0x52,
    fields: [
      auth_status: DataTypes.UInt32.t()
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<auth_status::uint32, <<>>::binary>>) do
    authentication_ok(auth_status: auth_status)
  end
end
