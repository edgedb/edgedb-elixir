defmodule Tests.EdgeDB.Protocol.Codecs.BytesTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Error

  setup :edgedb_connection

  test "decoding std::bytes value", %{conn: conn} do
    value = <<16, 13, 2, 42>>
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <bytes>b\"\x10\x0d\x02\x2a\"")
  end

  test "encoding std::bytes value", %{conn: conn} do
    value = <<16, 13, 2, 42>>
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <bytes>$0", [value])
  end

  test "error when passing non bytes as std::bytes argument", %{conn: conn} do
    value = 42

    exc =
      assert_raise Error, fn ->
        EdgeDB.query_one(conn, "SELECT <bytes>$0", [value])
      end

    assert exc == Error.invalid_argument_error("unable to encode #{value} as std::bytes")
  end
end
