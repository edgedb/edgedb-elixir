defmodule EdgeDB.Protocol.Messages.Client.RestoreEOF do
  use EdgeDB.Protocol.Message

  defmessage(
    client: true,
    mtype: 0x2E,
    name: :restore_eof
  )
end
