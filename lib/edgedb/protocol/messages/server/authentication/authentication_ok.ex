defmodule EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationOK do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Datatypes

  defmessage(
    name: :authentication_ok,
    server: true,
    mtype: 0x52,
    fields: [
      auth_status: Datatypes.UInt32.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<auth_status::uint32>>) do
    authentication_ok(auth_status: auth_status)
  end
end
