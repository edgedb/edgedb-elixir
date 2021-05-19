defmodule EdgeDB.Protocol.Messages.Server.DumpBlock do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Types

  defmessage(
    server: true,
    mtype: 0x3D,
    name: :dump_block,
    fields: [
      headers: [Types.Header.t()]
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, <<>>} = Types.Header.decode(num_headers, rest)
    dump_block(headers: headers)
  end
end
