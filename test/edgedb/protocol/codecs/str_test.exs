defmodule Tests.EdgeDB.Protocol.Codecs.StrTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding std::str value", %{conn: conn} do
    value = "Harry Potter and the Sorcerer's Stone"

    assert ^value =
             EdgeDB.query_single!(conn, "SELECT <str>\"Harry Potter and the Sorcerer's Stone\"")
  end

  test "encoding std::str value", %{conn: conn} do
    value = "Harry Potter and the Sorcerer's Stone"
    assert ^value = EdgeDB.query_single!(conn, "SELECT <str>$0", [value])
  end

  test "error when passing non str as std::str argument", %{conn: conn} do
    value = 42

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <str>$0", [value])
      end

    assert exc ==
             EdgeDB.Error.invalid_argument_error(
               "value can not be encoded as std::str: #{inspect(value)}"
             )
  end
end
