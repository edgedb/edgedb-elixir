defmodule EdgeDB.Protocol.Codecs.DateTime do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  @seconds_before_2000_1_1_utc 946_684_800

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-00000000010A"),
    type_name: "std::datetime",
    type: DateTime.t() | non_neg_integer()
  )

  @spec encode_instance(t()) :: bitstring()

  def encode_instance(unix_ts) when is_integer(unix_ts) do
    edb_datetime =
      System.convert_time_unit(unix_ts + @seconds_before_2000_1_1_utc, :second, :microsecond)

    DataTypes.Int64.encode(edb_datetime)
  end

  def encode_instance(%DateTime{} = dt) do
    dt
    |> DateTime.to_unix()
    |> encode_instance()
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<edb_datetime::int64>>) do
    unix_ts =
      System.convert_time_unit(edb_datetime, :microsecond, :second) - @seconds_before_2000_1_1_utc

    DateTime.from_unix!(unix_ts)
  end
end
