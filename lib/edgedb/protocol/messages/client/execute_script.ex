defmodule EdgeDB.Protocol.Messages.Client.ExecuteScript do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  defmessage(
    name: :execute_script,
    client: true,
    mtype: 0x51,
    fields: [
      headers: Keyword.t(),
      script: Datatypes.String.t()
    ],
    known_headers: %{
      allow_capabilities: [
        code: 0xFF04,
        encoder: Enums.Capability
      ]
    }
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(execute_script(headers: headers, script: script)) do
    headers = handle_headers(headers)

    [
      Types.Header.encode(headers),
      Datatypes.String.encode(script)
    ]
  end
end
