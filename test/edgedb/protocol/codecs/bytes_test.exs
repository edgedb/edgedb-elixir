defmodule Tests.EdgeDB.Protocol.Codecs.BytesTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Errors

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

    assert_raise Errors.InvalidArgumentError,
                 "unable to encode #{value} as std::bytes",
                 fn ->
                   EdgeDB.query_one(conn, "SELECT <bytes>$0", [value])
                 end
  end
end
