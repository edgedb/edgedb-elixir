defmodule EdgeDB.Protocol.Messages.Client.Prepare do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Enums,
    Types
  }

  defmessage(
    name: :prepare,
    client: true,
    mtype: 0x50,
    fields: [
      headers: [Types.Header.t()],
      io_format: Enums.IOFormat.t(),
      expected_cardinality: Enums.Cardinality.t(),
      statement_name: DataTypes.Bytes.t(),
      command: DataTypes.String.t()
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

  @spec encode_message(t()) :: iodata()
  defp encode_message(
         prepare(
           headers: headers,
           io_format: io_format,
           expected_cardinality: expected_cardinality,
           statement_name: statement_name,
           command: command
         )
       ) do
    processed_headers = process_headers(headers)

    [
      Types.Header.encode(processed_headers),
      Enums.IOFormat.encode(io_format),
      Enums.Cardinality.encode(expected_cardinality),
      DataTypes.Bytes.encode(statement_name),
      DataTypes.String.encode(command)
    ]
  end
end
