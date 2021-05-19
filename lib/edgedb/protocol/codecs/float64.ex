defmodule EdgeDB.Protocol.Codecs.Float64 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-000000000107"),
    type_name: "std::float64",
    type: DataTypes.Float64.t()
  )

  @spec encode_instance(t()) :: bitstring()
  def encode_instance(float) do
    DataTypes.Float64.encode(float)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(data) when is_bitstring(data) do
    {float, <<>>} = DataTypes.Float64.decode(data)
    float
  end
end
