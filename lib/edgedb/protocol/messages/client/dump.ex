defmodule EdgeDB.Protocol.Messages.Client.Dump do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Types

  defmessage(
    name: :dump,
    client: true,
    mtype: 0x3E,
    fields: [
      headers: [Types.Header.t()]
    ]
  )

  @spec encode_message(t()) :: iodata()
  defp encode_message(dump(headers: headers)) do
    [Types.Header.encode(headers)]
  end
end
