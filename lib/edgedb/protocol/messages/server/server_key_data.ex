defmodule EdgeDB.Protocol.Messages.Server.ServerKeyData do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Datatypes

  @key_data_length 32

  defmessage(
    server: true,
    mtype: 0x4B,
    fields: [
      data: list(Datatypes.UInt8.t())
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<data::binary>>) do
    {data, <<>>} = Datatypes.UInt8.decode(@key_data_length, data)
    %__MODULE__{data: data}
  end
end
