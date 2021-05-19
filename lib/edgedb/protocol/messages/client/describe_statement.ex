defmodule EdgeDB.Protocol.Messages.Client.DescribeStatement do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{DataTypes, Types, Enums}

  defmessage(
    client: true,
    mtype: 0x44,
    name: :describe_statement,
    fields: [
      headers: [Types.Header.t()],
      aspect: Enums.DescribeAspect.t(),
      statement_name: DataTypes.Bytes.t()
    ]
  )

  @spec encode_message(t()) :: bitstring()
  defp encode_message(
         describe_statement(
           headers: headers,
           aspect: aspect,
           statement_name: statement_name
         )
       ) do
    [
      Types.Header.encode(headers),
      Enums.DescribeAspect.encode(aspect),
      DataTypes.Bytes.encode(statement_name)
    ]
  end
end
