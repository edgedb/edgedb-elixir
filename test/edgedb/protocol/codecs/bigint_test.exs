defmodule Tests.EdgeDB.Protocol.Codecs.BigIntTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding std::bigint value", %{conn: conn} do
    value = Decimal.new(-15_000)
    assert ^value = EdgeDB.query_single!(conn, "select <bigint>-15000")
  end

  test "encoding Decimal as std::bigint value", %{conn: conn} do
    value = Decimal.new(-15_000)
    assert ^value = EdgeDB.query_single!(conn, "select <bigint>$0", [value])
  end

  test "encoding integer as std::bigint value", %{conn: conn} do
    value = 1
    expected_value = Decimal.new(1)
    assert ^expected_value = EdgeDB.query_single!(conn, "select <bigint>$0", [value])
  end

  test "error when passing non-number as std::bigint argument", %{conn: conn} do
    value = <<16, 13, 2, 42>>

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "select <bigint>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as std::bigint: #{inspect(value)}"
             )
  end

  test "error when passing float as std::bigint argument", %{conn: conn} do
    value = 1.0

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "select <bigint>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as std::bigint: value is float: #{inspect(value)}"
             )
  end

  test "error when passing non integer Decimal as std::bigint argument", %{conn: conn} do
    {value, ""} = Decimal.parse("-15000.6250000")

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "select <bigint>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as std::bigint: bigint numbers can not contain exponent part: #{inspect(value)}"
             )
  end
end
