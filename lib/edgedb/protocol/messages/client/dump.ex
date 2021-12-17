defmodule EdgeDB.Protocol.Messages.Client.Dump do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Types

  defmessage(
    name: :dump,
    client: true,
    mtype: 0x3E,
    fields: [
      headers: Keyword.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(dump(headers: headers)) do
    headers = handle_headers(headers)

    [Types.Header.encode(headers)]
  end
end
