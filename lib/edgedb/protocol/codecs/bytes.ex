defmodule EdgeDB.Protocol.Codecs.Bytes do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    calculate_size?: false,
    type_id: UUID.from_string("00000000-0000-0000-0000-000000000102"),
    type_name: "std::bytes",
    type: DataTypes.Bytes.t()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(bytes) when is_binary(bytes) do
    DataTypes.Bytes.encode(bytes)
  end

  @spec decode_instance(bitstring()) :: {t(), bitstring()}
  def decode_instance(data) when is_bitstring(data) do
    DataTypes.Bytes.decode(data)
  end
end
