defmodule Tests.EdgeDB.Protocol.Codecs.DecimalTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding std::decimal value", %{client: client} do
    {value, ""} = Decimal.parse("-15000.6250000")
    assert ^value = EdgeDB.query_single!(client, "select <decimal>-15000.6250000n")
  end

  test "encoding Decimal as std::decimal value", %{client: client} do
    {value, ""} = Decimal.parse("-15000.6250000")
    assert ^value = EdgeDB.query_single!(client, "select <decimal>$0", [value])
  end

  test "encoding integer as std::decimal value", %{client: client} do
    value = 1
    expected_value = Decimal.new(1)
    assert ^expected_value = EdgeDB.query_single!(client, "select <decimal>$0", [value])
  end

  test "encoding float as std::decimal value", %{client: client} do
    value = 1.0
    {expected_value, ""} = Decimal.parse("1.0")
    assert ^expected_value = EdgeDB.query_single!(client, "select <decimal>$0", [value])
  end

  test "error when passing non-number as std::decimal argument", %{client: client} do
    value = <<16, 13, 2, 42>>

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(client, "select <decimal>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as std::decimal: #{inspect(value)}"
             )
  end

  test "error when passing non-number Decimal as std::decimal argument", %{client: client} do
    value = %Decimal{coef: :inf}

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(client, "select <decimal>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as std::decimal: coef #{inspect(value.coef)} is not a number: #{inspect(value)}"
             )
  end
end
