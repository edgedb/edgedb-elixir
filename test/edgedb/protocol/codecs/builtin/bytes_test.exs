defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.BytesTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding std::bytes value", %{conn: conn} do
    value = <<16, 13, 2, 42>>
    assert ^value = EdgeDB.query_single!(conn, "SELECT <bytes>b\"\x10\x0d\x02\x2a\"")
  end

  test "encoding std::bytes value", %{conn: conn} do
    value = <<16, 13, 2, 42>>
    assert ^value = EdgeDB.query_single!(conn, "SELECT <bytes>$0", [value])
  end

  test "error when passing non bytes as std::bytes argument", %{conn: conn} do
    value = 42

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <bytes>$0", [value])
      end

    assert exc ==
             EdgeDB.Error.invalid_argument_error(
               "value can not be encoded as std::bytes: #{inspect(value)}"
             )
  end
end
