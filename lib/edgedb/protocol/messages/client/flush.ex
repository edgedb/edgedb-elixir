defmodule EdgeDB.Protocol.Messages.Client.Flush do
  use EdgeDB.Protocol.Message

  defmessage(
    name: :flush,
    client: true,
    mtype: 0x48
  )
end
