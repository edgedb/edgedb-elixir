defmodule Tests.EdgeDB.Protocol.Codecs.DecimalTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Errors

  setup :edgedb_connection

  test "decoding std::decimal value", %{conn: conn} do
    {value, ""} = Decimal.parse("-15000.6250000")
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <decimal>-15000.6250000n")
  end

  test "encoding Decimal as std::decimal value", %{conn: conn} do
    {value, ""} = Decimal.parse("-15000.6250000")
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <decimal>$0", [value])
  end

  test "encoding integer as std::decimal value", %{conn: conn} do
    value = 1
    expected_value = Decimal.new(1)
    assert {:ok, ^expected_value} = EdgeDB.query_one(conn, "SELECT <decimal>$0", [value])
  end

  test "encoding float as std::decimal value", %{conn: conn} do
    value = 1.0
    {expected_value, ""} = Decimal.parse("1.0")
    assert {:ok, ^expected_value} = EdgeDB.query_one(conn, "SELECT <decimal>$0", [value])
  end

  test "error when passing non-number as std::decimal argument", %{conn: conn} do
    value = <<16, 13, 2, 42>>

    assert_raise Errors.InvalidArgumentError,
                 "unable to encode #{inspect(value)} as std::decimal",
                 fn ->
                   EdgeDB.query_one(conn, "SELECT <decimal>$0", [value])
                 end
  end

  test "error when passing non-number Decimal as std::decimal argument", %{conn: conn} do
    value = %Decimal{coef: :inf}

    assert_raise Errors.InvalidArgumentError,
                 "unable to encode #{inspect(value)} as std::decimal: coef inf is not a number",
                 fn ->
                   EdgeDB.query_one(conn, "SELECT <decimal>$0", [value])
                 end
  end
end
