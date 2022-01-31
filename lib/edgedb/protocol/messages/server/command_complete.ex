defmodule EdgeDB.Protocol.Messages.Server.CommandComplete do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  defmessage(
    server: true,
    mtype: 0x43,
    fields: [
      headers: map(),
      status: Datatypes.String.t()
    ],
    known_headers: %{
      capabilities: [
        code: 0x1001,
        decoder: &Enums.Capability.exhaustive_decode/1
      ]
    }
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {status, <<>>} = Datatypes.String.decode(rest)

    %__MODULE__{
      headers: handle_headers(headers),
      status: status
    }
  end
end
