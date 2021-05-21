defmodule EdgeDB.Protocol.Codecs.LocalTime do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-00000000010D"),
    type_name: "cal::local_time",
    type: Time.t()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(%Time{} = t) do
    t
    |> Time.to_seconds_after_midnight()
    |> System.convert_time_unit(:second, :microsecond)
    |> DataTypes.Int64.encode()
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<ms::int64>>) do
    ms
    |> System.convert_time_unit(:microsecond, :second)
    |> Time.from_seconds_after_midnight()
  end
end
