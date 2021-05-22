defmodule EdgeDB.Protocol.Messages.Client.Execute do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defmessage(
    name: :execute,
    client: true,
    mtype: 0x45,
    fields: [
      headers: [Types.Header.t()],
      statement_name: DataTypes.Bytes.t(),
      arguments: iodata()
    ],
    defaults: [
      headers: [],
      statement_name: ""
    ]
  )

  @spec encode_message(t()) :: iodata()
  defp encode_message(
         execute(
           headers: headers,
           statement_name: statement_name,
           arguments: arguments
         )
       ) do
    [
      Types.Header.encode(headers),
      DataTypes.Bytes.encode(statement_name),
      arguments
    ]
  end
end
