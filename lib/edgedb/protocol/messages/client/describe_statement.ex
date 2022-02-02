defmodule EdgeDB.Protocol.Messages.Client.DescribeStatement do
  @moduledoc false

  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  @anonymous_statement ""

  defmessage(
    client: true,
    mtype: 0x44,
    fields: [
      headers: {map(), default: []},
      aspect: Enums.DescribeAspect.t(),
      statement_name: {Datatypes.Bytes.t(), default: @anonymous_statement}
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(%__MODULE__{
        headers: headers,
        aspect: aspect,
        statement_name: statement_name
      }) do
    headers = handle_headers(headers)

    [
      Types.Header.encode(headers),
      Enums.DescribeAspect.encode(aspect),
      Datatypes.Bytes.encode(statement_name)
    ]
  end
end
