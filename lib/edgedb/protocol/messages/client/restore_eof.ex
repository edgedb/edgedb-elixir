defmodule EdgeDB.Protocol.Messages.Client.RestoreEOF do
  use EdgeDB.Protocol.Message

  defmessage(
    name: :restore_eof,
    client: true,
    mtype: 0x2E
  )
end
