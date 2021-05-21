defmodule EdgeDB.Protocol.Messages.Server.CommandComplete do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defmessage(
    name: :command_complete,
    server: true,
    mtype: 0x43,
    fields: [
      headers: [Types.Header.t()],
      status: DataTypes.String.t()
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {status, <<>>} = DataTypes.String.decode(rest)
    command_complete(headers: headers, status: status)
  end
end
