defmodule EdgeDB.Protocol.Codecs.Duration do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  @days 0
  @months 0

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-00000000010E"),
    type_name: "std::duration",
    type: pos_integer()
  )

  @spec encode_instance(t()) :: bitstring()
  def encode_instance(duration) when is_integer(duration) do
    [
      DataTypes.Int64.encode(duration),
      DataTypes.Int32.encode(@days),
      DataTypes.Int32.encode(@months)
    ]
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<duration::int64, @days::int32, @months::int32>>) do
    duration
  end
end
