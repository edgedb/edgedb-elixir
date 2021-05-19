defmodule EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationOK do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  defmessage(
    server: true,
    mtype: 0x52,
    name: :authentication_ok,
    fields: [
      auth_status: DataTypes.UInt32.t()
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<auth_status::uint32, <<>>::binary>>) do
    authentication_ok(auth_status: auth_status)
  end
end
