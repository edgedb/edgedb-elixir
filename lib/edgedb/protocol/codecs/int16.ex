defmodule EdgeDB.Protocol.Codecs.Int16 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  defbasescalarcodec(
    type_name: "std::int16",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000103"),
    type: Datatypes.Int16.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(number) do
    Datatypes.Int16.encode(number)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<number::int16>>) do
    number
  end
end
