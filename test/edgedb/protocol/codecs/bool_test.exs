defmodule Tests.EdgeDB.Protocol.Codecs.BoolTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Errors

  setup :edgedb_connection

  test "decoding std::bool value", %{conn: conn} do
    value = true

    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <bool>true")
  end

  test "encoding std::bool value", %{conn: conn} do
    value = false
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <bool>$0", [value])
  end

  test "error when passing non bool as std::bool argument", %{conn: conn} do
    value = 42

    assert_raise Errors.InvalidArgumentError,
                 "unable to encode #{value} as std::bool",
                 fn ->
                   EdgeDB.query_one(conn, "SELECT <bool>$0", [value])
                 end
  end
end
