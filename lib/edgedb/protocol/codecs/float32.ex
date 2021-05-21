defmodule EdgeDB.Protocol.Codecs.Float32 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-000000000106"),
    type_name: "std::float32",
    type: DataTypes.Float32.t()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(float) do
    DataTypes.Float32.encode(float)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(data) when is_bitstring(data) do
    {float, <<>>} = DataTypes.Float32.decode(data)
    float
  end
end
