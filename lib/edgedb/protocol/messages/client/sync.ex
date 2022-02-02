defmodule EdgeDB.Protocol.Messages.Client.Sync do
  @moduledoc false

  use EdgeDB.Protocol.Message

  defmessage(
    client: true,
    mtype: 0x53
  )
end
