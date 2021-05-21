defmodule EdgeDB.Protocol.Messages.Client.Terminate do
  use EdgeDB.Protocol.Message

  defmessage(
    name: :terminate,
    client: true,
    mtype: 0x58
  )
end
