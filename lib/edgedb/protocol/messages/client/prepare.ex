defmodule EdgeDB.Protocol.Messages.Client.Prepare do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  defmessage(
    name: :prepare,
    client: true,
    mtype: 0x50,
    fields: [
      headers: Keyword.t(),
      io_format: Enums.IOFormat.t(),
      expected_cardinality: Enums.Cardinality.t(),
      statement_name: Datatypes.Bytes.t(),
      command: Datatypes.String.t()
    ],
    defaults: [
      headers: [],
      statement_name: ""
    ],
    known_headers: %{
      implicit_limit: 0xFF01,
      implicit_typenames: 0xFF02,
      implicit_typeids: 0xFF03,
      allow_capabilities: {0xFF04, &Enums.Capability.encode/1},
      explicit_objectids: 0xFF05
    }
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(
        prepare(
          headers: headers,
          io_format: io_format,
          expected_cardinality: expected_cardinality,
          statement_name: statement_name,
          command: command
        )
      ) do
    headers = process_passed_headers(headers)

    [
      Types.Header.encode(headers),
      Enums.IOFormat.encode(io_format),
      Enums.Cardinality.encode(expected_cardinality),
      Datatypes.Bytes.encode(statement_name),
      Datatypes.String.encode(command)
    ]
  end
end
