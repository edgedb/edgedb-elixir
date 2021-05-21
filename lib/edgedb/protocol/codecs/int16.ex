defmodule EdgeDB.Protocol.Codecs.Int16 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-000000000103"),
    type_name: "std::int16",
    type: integer()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(integer) when is_integer(integer) do
    DataTypes.Int16.encode(integer)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<integer::int16>>) do
    integer
  end
end
