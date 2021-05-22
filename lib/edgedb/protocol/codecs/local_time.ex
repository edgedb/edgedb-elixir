defmodule EdgeDB.Protocol.Codecs.LocalTime do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_name: "cal::local_time",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-00000000010D"),
    type: Time.t()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(%Time{} = time) do
    {seconds, microseconds} = Time.to_seconds_after_midnight(time)
    microseconds = microseconds + System.convert_time_unit(seconds, :second, :microsecond)

    DataTypes.Int64.encode(microseconds)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<ms::int64>>) do
    ms
    |> System.convert_time_unit(:microsecond, :second)
    |> Time.from_seconds_after_midnight()
  end
end
