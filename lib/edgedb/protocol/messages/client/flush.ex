defmodule EdgeDB.Protocol.Messages.Client.Flush do
  @moduledoc false

  use EdgeDB.Protocol.Message

  defmessage(
    client: true,
    mtype: 0x48
  )
end
