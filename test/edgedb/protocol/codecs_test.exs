defmodule Tests.EdgeDB.Protocol.CodecsTest do
  use Tests.Support.EdgeDBCase

  @builtin_scalar_codecs %{
    "std::uuid" => EdgeDB.Protocol.Codecs.UUID,
    "std::str" => EdgeDB.Protocol.Codecs.Str,
    "std::bytes" => EdgeDB.Protocol.Codecs.Bytes,
    "std::int16" => EdgeDB.Protocol.Codecs.Int16,
    "std::int32" => EdgeDB.Protocol.Codecs.Int32,
    "std::int64" => EdgeDB.Protocol.Codecs.Int64,
    "std::float32" => EdgeDB.Protocol.Codecs.Float32,
    "std::float64" => EdgeDB.Protocol.Codecs.Float64,
    "std::decimal" => EdgeDB.Protocol.Codecs.Decimal,
    "std::bool" => EdgeDB.Protocol.Codecs.Bool,
    "std::datetime" => EdgeDB.Protocol.Codecs.DateTime,
    "std::duration" => EdgeDB.Protocol.Codecs.Duration,
    "std::json" => EdgeDB.Protocol.Codecs.JSON,
    "cal::local_datetime" => EdgeDB.Protocol.Codecs.LocalDateTime,
    "cal::local_date" => EdgeDB.Protocol.Codecs.LocalDate,
    "cal::local_time" => EdgeDB.Protocol.Codecs.LocalTime,
    "std::bigint" => EdgeDB.Protocol.Codecs.BigInt,
    "cal::relative_duration" => EdgeDB.Protocol.Codecs.RelativeDuration,
    "cfg::memory" => EdgeDB.Protocol.Codecs.ConfigMemory
  }

  describe "scalar codec" do
    for {name, codec_mod} <- @builtin_scalar_codecs do
      test "#{name} returns full qualified name from #{codec_mod}.name/0" do
        assert unquote(codec_mod).name() == unquote(name)
      end
    end
  end
end
