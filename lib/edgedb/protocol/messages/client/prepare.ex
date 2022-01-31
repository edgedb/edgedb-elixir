defmodule EdgeDB.Protocol.Messages.Client.Prepare do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  @anonymous_statement ""

  defmessage(
    client: true,
    mtype: 0x50,
    fields: [
      headers: map(),
      io_format: Enums.IOFormat.t(),
      expected_cardinality: Enums.Cardinality.t(),
      statement_name: {Datatypes.Bytes.t(), default: @anonymous_statement},
      command: Datatypes.String.t()
    ],
    known_headers: %{
      implicit_limit: [
        code: 0xFF01
      ],
      implicit_typenames: [
        code: 0xFF02
      ],
      implicit_typeids: [
        code: 0xFF03
      ],
      allow_capabilities: [
        code: 0xFF04,
        encoder: Enums.Capability
      ],
      explicit_objectids: [
        code: 0xFF05
      ]
    }
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(%__MODULE__{
        headers: headers,
        io_format: io_format,
        expected_cardinality: expected_cardinality,
        statement_name: statement_name,
        command: command
      }) do
    headers = handle_headers(headers || [])

    [
      Types.Header.encode(headers),
      Enums.IOFormat.encode(io_format),
      Enums.Cardinality.encode(expected_cardinality),
      Datatypes.Bytes.encode(statement_name),
      Datatypes.String.encode(command)
    ]
  end
end
