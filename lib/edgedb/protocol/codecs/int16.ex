defmodule EdgeDB.Protocol.Codecs.Int16 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_name: "std::int16",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-000000000103"),
    type: integer()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(number) do
    DataTypes.Int16.encode(number)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<number::int16>>) do
    number
  end
end
