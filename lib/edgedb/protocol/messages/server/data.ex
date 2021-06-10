defmodule EdgeDB.Protocol.Messages.Server.Data do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Types

  defmessage(
    name: :data,
    server: true,
    mtype: 0x44,
    fields: [
      data: list(Types.DataElement.t())
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<num_data::uint16, rest::binary>>) do
    {data, <<>>} = Types.DataElement.decode(num_data, rest)
    data(data: data)
  end
end
