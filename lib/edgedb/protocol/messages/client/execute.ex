defmodule EdgeDB.Protocol.Messages.Client.Execute do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  defmessage(
    name: :execute,
    client: true,
    mtype: 0x45,
    fields: [
      headers: Keyword.t(),
      statement_name: Datatypes.Bytes.t(),
      arguments: iodata()
    ],
    defaults: [
      headers: [],
      statement_name: ""
    ],
    known_headers: %{
      allow_capabilities: {0xFF04, %{encoder: &Enums.Capability.encode/1}}
    }
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(
        execute(
          headers: headers,
          statement_name: statement_name,
          arguments: arguments
        )
      ) do
    headers = process_passed_headers(headers)

    [
      Types.Header.encode(headers),
      Datatypes.Bytes.encode(statement_name),
      arguments
    ]
  end
end
