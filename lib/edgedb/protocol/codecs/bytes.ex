defmodule EdgeDB.Protocol.Codecs.Bytes do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_name: "std::bytes",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-000000000102"),
    type: DataTypes.Bytes.t(),
    calculate_size?: false
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(bytes) do
    DataTypes.Bytes.encode(bytes)
  end

  @spec decode_instance(bitstring()) :: {t(), bitstring()}
  def decode_instance(data) do
    {bytes, <<>>} = DataTypes.Bytes.decode(data)
    bytes
  end
end
