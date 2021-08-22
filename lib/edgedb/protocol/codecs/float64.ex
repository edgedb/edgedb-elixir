defmodule EdgeDB.Protocol.Codecs.Float64 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  defbuiltinscalarcodec(
    type_name: "std::float64",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000107"),
    type: Datatypes.Float64.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(number) do
    Datatypes.Float64.encode(number)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(data) do
    {number, <<>>} = Datatypes.Float64.decode(data)
    number
  end
end
