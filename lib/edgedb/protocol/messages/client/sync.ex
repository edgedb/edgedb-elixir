defmodule EdgeDB.Protocol.Messages.Client.Sync do
  use EdgeDB.Protocol.Message

  defmessage(
    name: :sync,
    client: true,
    mtype: 0x53
  )
end
