defmodule EdgeDB.Protocol.Codecs.Float32 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  defbasescalarcodec(
    type_name: "std::float32",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000106"),
    type: Datatypes.Float32.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(number) do
    Datatypes.Float32.encode(number)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(data) do
    {number, <<>>} = Datatypes.Float32.decode(data)
    number
  end
end
