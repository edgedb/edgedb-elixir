defmodule EdgeDB.Protocol.Messages.Client.DescribeStatement do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  defmessage(
    name: :describe_statement,
    client: true,
    mtype: 0x44,
    fields: [
      headers: Keyword.t(),
      aspect: Enums.DescribeAspect.t(),
      statement_name: Datatypes.Bytes.t()
    ],
    defaults: [
      headers: [],
      statement_name: ""
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
    headers = process_passed_headers(headers)

    [
      Types.Header.encode(headers),
      Enums.DescribeAspect.encode(aspect),
      Datatypes.Bytes.encode(statement_name)
    ]
  end
end
