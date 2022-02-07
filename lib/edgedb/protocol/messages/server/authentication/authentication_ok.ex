defmodule EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationOK do
  @moduledoc false

  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Datatypes

  defmessage(
    server: true,
    mtype: 0x52,
    fields: [
      auth_status: Datatypes.UInt32.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<auth_status::uint32>>) do
    %__MODULE__{auth_status: auth_status}
  end
end
