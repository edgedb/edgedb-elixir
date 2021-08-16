defmodule Tests.EdgeDB.Protocol.Codecs.EnumTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Error

  setup :edgedb_connection

  test "decoding enum value", %{conn: conn} do
    value = "Green"
    assert ^value = EdgeDB.query_single!(conn, "SELECT <Color>'Green'")
  end

  test "encoding string to enum value", %{conn: conn} do
    value = "Green"
    assert ^value = EdgeDB.query_single!(conn, "SELECT <Color>$0", [value])
  end

  test "error when encoding not member element to enum value", %{conn: conn} do
    value = "White"

    exc =
      assert_raise Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <Color>$0", [value])
      end

    assert exc ==
             Error.invalid_argument_error(
               "unable to encode #{inspect(value)} as enum: #{inspect(value)} is not member of enum"
             )
  end
end
