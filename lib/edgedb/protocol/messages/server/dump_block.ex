defmodule EdgeDB.Protocol.Messages.Server.DumpBlock do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  defmessage(
    name: :dump_block,
    server: true,
    mtype: 0x3D,
    fields: [
      headers: Keyword.t()
    ],
    known_headers: %{
      block_type: 101,
      block_id: {110, %{decoder: &Datatypes.UUID.decode/1}},
      block_num: 111,
      block_data: 112
    }
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, <<>>} = Types.Header.decode(num_headers, rest)

    dump_block(headers: process_received_headers(headers))
  end
end
