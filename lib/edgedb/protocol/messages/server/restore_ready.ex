defmodule EdgeDB.Protocol.Messages.Server.RestoreReady do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  defmessage(
    server: true,
    mtype: 0x2B,
    fields: [
      headers: Keyword.t(),
      jobs: Datatypes.UInt16.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {jobs, <<>>} = Datatypes.UInt16.decode(rest)

    %__MODULE__{
      headers: handle_headers(headers),
      jobs: jobs
    }
  end
end
