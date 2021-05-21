defmodule EdgeDB.Protocol.Messages.Client.Restore do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defmessage(
    name: :restore,
    client: true,
    mtype: 0x3C,
    fields: [
      headers: [Types.Header.t()],
      jobs: DataTypes.UInt16.t(),
      header_data: DataTypes.Bytes.t()
    ]
  )

  @spec encode_message(t()) :: iodata()
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
