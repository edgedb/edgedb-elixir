defmodule EdgeDB.Protocol.Codecs.Builtin.RelativeDuration do
  @moduledoc false

  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes
  alias EdgeDB.RelativeDuration

  defbuiltinscalarcodec(
    type_name: "cal::relative_duration",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000111"),
    type: RelativeDuration.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(%RelativeDuration{} = duration) do
    [
      Datatypes.Int64.encode(duration.microseconds),
      Datatypes.Int32.encode(duration.days),
      Datatypes.Int32.encode(duration.months)
    ]
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<microseconds::int64, days::int32, months::int32>>) do
    %RelativeDuration{
      microseconds: microseconds,
      days: days,
      months: months
    }
  end
end
