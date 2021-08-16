defmodule Tests.EdgeDB.Protocol.Codecs.BigIntTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Error

  setup :edgedb_connection

  test "decoding std::bigint value", %{conn: conn} do
    value = Decimal.new(-15_000)
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <bigint>-15000")
  end

  test "encoding Decimal as std::bigint value", %{conn: conn} do
    value = Decimal.new(-15_000)
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <bigint>$0", [value])
  end

  test "encoding integer as std::bigint value", %{conn: conn} do
    value = 1
    expected_value = Decimal.new(1)
    assert {:ok, ^expected_value} = EdgeDB.query_single(conn, "SELECT <bigint>$0", [value])
  end

  test "error when passing non-number as std::bigint argument", %{conn: conn} do
    value = <<16, 13, 2, 42>>

    exc =
      assert_raise Error, fn ->
        EdgeDB.query_single(conn, "SELECT <bigint>$0", [value])
      end

    assert exc ==
             Error.invalid_argument_error("unable to encode #{inspect(value)} as std::bigint")
  end

  test "error when passing float as std::bigint argument", %{conn: conn} do
    value = 1.0

    exc =
      assert_raise Error, fn ->
        EdgeDB.query_single(conn, "SELECT <bigint>$0", [value])
      end

    assert exc ==
             Error.invalid_argument_error(
               "unable to encode #{inspect(value)} as std::bigint: floats can't be encoded"
             )
  end

  test "error when passing non integer Decimal as std::bigint argument", %{conn: conn} do
    {value, ""} = Decimal.parse("-15000.6250000")

    exc =
      assert_raise Error, fn ->
        EdgeDB.query_single(conn, "SELECT <bigint>$0", [value])
      end

    assert exc ==
             Error.invalid_argument_error(
               "unable to encode #{inspect(value)} as std::bigint: bigint numbers can't contain exponent"
             )
  end
end
