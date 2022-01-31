defmodule EdgeDB.Protocol.Messages.Client.Execute do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  @anonymous_statement ""

  defmessage(
    client: true,
    mtype: 0x45,
    fields: [
      headers: map(),
      statement_name: {Datatypes.Bytes.t(), default: @anonymous_statement},
      arguments: iodata()
    ],
    known_headers: %{
      allow_capabilities: [
        code: 0xFF04,
        encoder: Enums.Capability
      ]
    }
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(%__MODULE__{
        headers: headers,
        statement_name: statement_name,
        arguments: arguments
      }) do
    headers = handle_headers(headers)

    [
      Types.Header.encode(headers),
      Datatypes.Bytes.encode(statement_name || @anonymous_statement),
      arguments
    ]
  end
end
