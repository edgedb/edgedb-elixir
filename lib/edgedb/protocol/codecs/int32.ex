defmodule EdgeDB.Protocol.Codecs.Int32 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_name: "std::int32",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-000000000104"),
    type: integer()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(integer) do
    DataTypes.Int32.encode(integer)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<number::int32>>) do
    number
  end
end
