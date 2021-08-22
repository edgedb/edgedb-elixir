defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.StrTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Error

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
      assert_raise Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <str>$0", [value])
      end

    assert exc == Error.invalid_argument_error("unable to encode #{value} as std::str")
  end
end
