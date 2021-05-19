defmodule EdgeDB.Protocol.Messages.Client.Terminate do
  use EdgeDB.Protocol.Message

  defmessage(
    client: true,
    mtype: 0x58,
    name: :terminate
  )
end
