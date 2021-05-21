defmodule EdgeDB.Protocol.Codecs.Int64 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-000000000105"),
    type_name: "std::int64",
    type: integer()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(integer) when is_integer(integer) do
    DataTypes.Int64.encode(integer)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<integer::int64>>) do
    integer
  end
end
