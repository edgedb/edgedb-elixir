defmodule Tests.EdgeDB.Protocol.Codecs.StrTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Errors

  setup :edgedb_connection

  test "decoding std::str value", %{conn: conn} do
    value = "Harry Potter and the Sorcerer's Stone"

    assert {:ok, ^value} =
             EdgeDB.query_one(conn, "SELECT <str>\"Harry Potter and the Sorcerer's Stone\"")
  end

  test "encoding std::str value", %{conn: conn} do
    value = "Harry Potter and the Sorcerer's Stone"
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <str>$0", [value])
  end

  test "error when passing non str as std::str argument", %{conn: conn} do
    value = 42

    assert_raise Errors.InvalidArgumentError,
                 "unable to encode #{value} as std::str",
                 fn ->
                   EdgeDB.query_one(conn, "SELECT <str>$0", [value])
                 end
  end
end
