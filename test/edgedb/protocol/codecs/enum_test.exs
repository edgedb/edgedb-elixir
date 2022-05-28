defmodule Tests.EdgeDB.Protocol.Codecs.EnumTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding enum value", %{conn: conn} do
    value = "Green"
    assert ^value = EdgeDB.query_single!(conn, "select <Color>'Green'")
  end

  test "encoding string to enum value", %{conn: conn} do
    value = "Green"
    assert ^value = EdgeDB.query_single!(conn, "select <Color>$0", [value])
  end

  test "error when encoding not member element to enum value", %{conn: conn} do
    value = "White"

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "select <Color>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as enum: not enum member: #{inspect(value)}"
             )
  end
end
