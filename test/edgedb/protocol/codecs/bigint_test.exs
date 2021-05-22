defmodule Tests.EdgeDB.Protocol.Codecs.BigIntTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Errors

  setup :edgedb_connection

  test "decoding std::bigint value", %{conn: conn} do
    value = Decimal.new(-15_000)
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <bigint>-15000")
  end

  test "encoding Decimal as std::bigint value", %{conn: conn} do
    value = Decimal.new(-15_000)
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <bigint>$0", [value])
  end

  test "encoding integer as std::bigint value", %{conn: conn} do
    value = 1
    expected_value = Decimal.new(1)
    assert {:ok, ^expected_value} = EdgeDB.query_one(conn, "SELECT <bigint>$0", [value])
  end

  test "error when passing non-number as std::bigint argument", %{conn: conn} do
    value = <<16, 13, 2, 42>>

    assert_raise Errors.InvalidArgumentError,
                 "unable to encode #{inspect(value)} as std::bigint",
                 fn ->
                   EdgeDB.query_one(conn, "SELECT <bigint>$0", [value])
                 end
  end

  test "error when passing float as std::bigint argument", %{conn: conn} do
    value = 1.0

    assert_raise Errors.InvalidArgumentError,
                 "unable to encode #{inspect(value)} as std::bigint: floats can't be encoded",
                 fn ->
                   EdgeDB.query_one(conn, "SELECT <bigint>$0", [value])
                 end
  end

  test "error when passing non integer Decimal as std::bigint argument", %{conn: conn} do
    {value, ""} = Decimal.parse("-15000.6250000")

    assert_raise Errors.InvalidArgumentError,
                 "unable to encode #{inspect(value)} as std::bigint: bigint numbers can't contain exponent",
                 fn ->
                   EdgeDB.query_one(conn, "SELECT <bigint>$0", [value])
                 end
  end
end
