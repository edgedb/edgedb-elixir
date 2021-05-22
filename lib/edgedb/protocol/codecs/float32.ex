defmodule EdgeDB.Protocol.Codecs.Float32 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_name: "std::float32",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-000000000106"),
    type: DataTypes.Float32.t()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(number) do
    DataTypes.Float32.encode(number)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(data) do
    {number, <<>>} = DataTypes.Float32.decode(data)
    number
  end
end
