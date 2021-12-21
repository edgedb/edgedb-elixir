defmodule EdgeDB.Protocol.Codecs.Builtin.Bytes do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  defbuiltinscalarcodec(
    type_name: "std::bytes",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000102"),
    type: Datatypes.Bytes.t(),
    calculate_size: false
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(bytes) do
    Datatypes.Bytes.encode(bytes)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(data) do
    {bytes, <<>>} = Datatypes.Bytes.decode(data)
    bytes
  end
end
