defmodule EdgeDB.Protocol.Codecs.Int32 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-000000000104"),
    type_name: "std::int32",
    type: integer()
  )

  @spec encode_instance(t()) :: bitstring()
  def encode_instance(integer) when is_integer(integer) do
    DataTypes.Int32.encode(integer)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<integer::int32>>) do
    integer
  end
end
