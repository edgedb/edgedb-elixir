defmodule EdgeDB.Protocol.Messages.Client.Restore do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  defmessage(
    client: true,
    mtype: 0x3C,
    fields: [
      headers: map(),
      jobs: Datatypes.UInt16.t(),
      header_data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(%__MODULE__{
        headers: headers,
        jobs: jobs,
        header_data: header_data
      }) do
    headers = handle_headers(headers)

    [
      Types.Header.encode(headers),
      Datatypes.UInt16.encode(jobs),
      Datatypes.Bytes.encode(header_data)
    ]
  end
end
