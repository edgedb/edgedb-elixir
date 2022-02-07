defmodule EdgeDB.Protocol.Codecs.Builtin.LocalTime do
  @moduledoc false

  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  defbuiltinscalarcodec(
    type_name: "cal::local_time",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-00000000010D"),
    type: Time.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(%Time{} = time) do
    {seconds, microseconds} = Time.to_seconds_after_midnight(time)
    microseconds = microseconds + System.convert_time_unit(seconds, :second, :microsecond)

    Datatypes.Int64.encode(microseconds)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<ms::int64>>) do
    ms
    |> System.convert_time_unit(:microsecond, :second)
    |> Time.from_seconds_after_midnight()
  end
end
