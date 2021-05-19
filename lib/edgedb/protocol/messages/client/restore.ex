defmodule EdgeDB.Protocol.Messages.Client.Restore do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{DataTypes, Types}

  defmessage(
    client: true,
    mtype: 0x3C,
    name: :restore,
    fields: [
      headers: [Types.Header.t()],
      jobs: DataTypes.UInt16.t(),
      header_data: DataTypes.Bytes.t()
    ]
  )

  @spec encode_message(t()) :: bitstring()
  defp encode_message(
         restore(
           headers: headers,
           jobs: jobs,
           header_data: header_data
         )
       ) do
    [
      Types.Header.encode(headers),
      DataTypes.UInt16.encode(jobs),
      DataTypes.Bytes.encode(header_data)
    ]
  end
end
