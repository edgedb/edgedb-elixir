defmodule EdgeDB.Protocol.Messages.Client.DescribeStatement do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  @anonymous_statement ""

  defmessage(
    name: :describe_statement,
    client: true,
    mtype: 0x44,
    fields: [
      headers: Keyword.t(),
      aspect: Enums.DescribeAspect.t(),
      statement_name: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(
        describe_statement(
          headers: headers,
          aspect: aspect,
          statement_name: statement_name
        )
      ) do
    headers = handle_headers(headers)

    [
      Types.Header.encode(headers),
      Enums.DescribeAspect.encode(aspect),
      Datatypes.Bytes.encode(statement_name || @anonymous_statement)
    ]
  end
end
