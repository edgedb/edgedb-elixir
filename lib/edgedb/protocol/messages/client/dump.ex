defmodule EdgeDB.Protocol.Messages.Client.Dump do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Types

  defmessage(
    client: true,
    mtype: 0x3E,
    name: :dump,
    fields: [
      headers: [Types.Header.t()]
    ]
  )

  @spec encode_message(t()) :: bitstring()
  defp encode_message(dump(headers: headers)) do
    [Types.Header.encode(headers)]
  end
end
