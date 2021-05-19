defmodule EdgeDB.Protocol.Messages.Client.Flush do
  use EdgeDB.Protocol.Message

  defmessage(
    client: true,
    mtype: 0x48,
    name: :flush
  )
end
