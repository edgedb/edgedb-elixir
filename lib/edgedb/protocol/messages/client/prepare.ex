defmodule EdgeDB.Protocol.Messages.Client.Prepare do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{DataTypes, Types, Enums}

  defmessage(
    client: true,
    mtype: 0x50,
    name: :prepare,
    fields: [
      headers: [Types.Header.t()],
      io_format: Enums.IOFormat.t(),
      expected_cardinality: Enums.Cardinality.t(),
      statement_name: DataTypes.Bytes.t(),
      command: DataTypes.String.t()
    ]
  )

  @spec encode_message(t()) :: bitstring()
  defp encode_message(
         prepare(
           headers: headers,
           io_format: io_format,
           expected_cardinality: expected_cardinality,
           statement_name: statement_name,
           command: command
         )
       ) do
    [
      Types.Header.encode(headers),
      Enums.IOFormat.encode(io_format),
      Enums.Cardinality.encode(expected_cardinality),
      DataTypes.Bytes.encode(statement_name),
      DataTypes.String.encode(command)
    ]
  end
end
