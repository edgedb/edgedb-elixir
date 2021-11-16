defmodule EdgeDB.Protocol.Codecs.ConfigMemory do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  defbuiltinscalarcodec(
    type_name: "cfg::memory",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000130"),
    type: EdgeDB.ConfigMemory.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(%EdgeDB.ConfigMemory{} = memory) do
    encode_instance(memory.bytes)
  end

  @impl EdgeDB.Protocol.Codec
  def encode_instance(memory) when is_integer(memory) do
    Datatypes.Int64.encode(memory)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(data) do
    {bytes, <<>>} = Datatypes.Int64.decode(data)
    %EdgeDB.ConfigMemory{bytes: bytes}
  end
end
