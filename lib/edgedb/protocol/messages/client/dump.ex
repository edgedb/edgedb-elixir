defmodule EdgeDB.Protocol.Messages.Client.Dump do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Types

  defmessage(
    client: true,
    mtype: 0x3E,
    fields: [
      headers: map()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(%__MODULE__{headers: headers}) do
    headers = handle_headers(headers)

    [Types.Header.encode(headers)]
  end
end
