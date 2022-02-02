defmodule EdgeDB.Protocol.Messages.Client.RestoreEOF do
  @moduledoc false

  use EdgeDB.Protocol.Message

  defmessage(
    client: true,
    mtype: 0x2E
  )
end
