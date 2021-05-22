defmodule EdgeDB.Protocol.Codecs.Bool do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  @true_code 1
  @false_code 0

  defbasescalarcodec(
    type_name: "std::bool",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-000000000109"),
    type: boolean()
  )

  @spec encode_instance(t()) :: iodata()

  def encode_instance(true) do
    DataTypes.Int8.encode(@true_code)
  end

  def encode_instance(false) do
    DataTypes.Int8.encode(@false_code)
  end

  @spec decode_instance(bitstring()) :: t()

  def decode_instance(<<@true_code::int8>>) do
    true
  end

  def decode_instance(<<@false_code::int8>>) do
    false
  end
end
