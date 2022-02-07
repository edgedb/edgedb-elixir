defmodule EdgeDB.Protocol.Messages.Client.Terminate do
  @moduledoc false

  use EdgeDB.Protocol.Message

  defmessage(
    client: true,
    mtype: 0x58
  )
end
