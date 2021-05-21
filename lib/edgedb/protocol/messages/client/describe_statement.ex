defmodule EdgeDB.Protocol.Messages.Client.DescribeStatement do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Enums,
    Types
  }

  defmessage(
    name: :describe_statement,
    client: true,
    mtype: 0x44,
    fields: [
      headers: [Types.Header.t()],
      aspect: Enums.DescribeAspect.t(),
      statement_name: DataTypes.Bytes.t()
    ]
  )

  @spec encode_message(t()) :: iodata()
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
