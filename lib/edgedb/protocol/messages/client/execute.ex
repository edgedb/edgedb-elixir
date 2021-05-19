defmodule EdgeDB.Protocol.Messages.Client.Execute do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{DataTypes, Types}

  defmessage(
    client: true,
    mtype: 0x45,
    name: :execute,
    fields: [
      headers: [Types.Header.t()],
      statement_name: DataTypes.Bytes.t(),
      arguments: iodata()
    ]
  )

  @spec encode_message(t()) :: bitstring()
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
