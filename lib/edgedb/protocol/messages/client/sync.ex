defmodule EdgeDB.Protocol.Messages.Client.Sync do
  use EdgeDB.Protocol.Message

  defmessage(
    client: true,
    mtype: 0x53,
    name: :sync
  )
end
