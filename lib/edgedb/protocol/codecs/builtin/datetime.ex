defmodule EdgeDB.Protocol.Codecs.Builtin.DateTime do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  @seconds_before_2000_1_1_utc 946_684_800

  defbuiltinscalarcodec(
    type_name: "std::datetime",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-00000000010A"),
    type: DateTime.t() | integer()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(unix_ts) when is_integer(unix_ts) do
    edb_datetime =
      System.convert_time_unit(unix_ts - @seconds_before_2000_1_1_utc, :second, :microsecond)

    Datatypes.Int64.encode(edb_datetime)
  end

  @impl EdgeDB.Protocol.Codec
  def encode_instance(%DateTime{} = dt) do
    dt
    |> DateTime.to_unix()
    |> encode_instance()
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<edb_datetime::int64>>) do
    unix_ts =
      System.convert_time_unit(edb_datetime, :microsecond, :second) + @seconds_before_2000_1_1_utc

    DateTime.from_unix!(unix_ts)
  end
end
