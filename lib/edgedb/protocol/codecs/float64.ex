defmodule EdgeDB.Protocol.Codecs.Float64 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_name: "std::float64",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-000000000107"),
    type: DataTypes.Float64.t()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(number) do
    DataTypes.Float64.encode(number)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(data) do
    {number, <<>>} = DataTypes.Float64.decode(data)
    number
  end
end
