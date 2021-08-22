defmodule EdgeDB.Protocol.Codecs.Int32 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  defbuiltinscalarcodec(
    type_name: "std::int32",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000104"),
    type: Datatypes.Int32.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(integer) do
    Datatypes.Int32.encode(integer)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<number::int32>>) do
    number
  end
end
