defmodule EdgeDB.Protocol.Messages.Server.Data do
  @moduledoc false

  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Types

  defmessage(
    server: true,
    mtype: 0x44,
    fields: [
      data: list(Types.DataElement.t())
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<num_data::uint16, rest::binary>>) do
    {data, <<>>} = Types.DataElement.decode(num_data, rest)
    %__MODULE__{data: data}
  end
end
