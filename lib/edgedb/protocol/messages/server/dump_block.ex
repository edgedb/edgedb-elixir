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
      block_type: [
        code: 101
      ],
      block_id: [
        code: 110,
        decoder: Datatypes.UUID
      ],
      block_num: [
        code: 111
      ],
      block_data: [
        code: 112
      ]
    }
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, <<>>} = Types.Header.decode(num_headers, rest)

    dump_block(headers: handle_headers(headers))
  end
end
