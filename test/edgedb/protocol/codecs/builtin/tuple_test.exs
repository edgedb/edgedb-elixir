defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.TupleTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding tuple value", %{conn: conn} do
    value = {1, "string", true, 1.0}
    assert ^value = EdgeDB.query_single!(conn, "SELECT (1, \"string\", true, 1.0)")
  end

  test "encoding passed arguments", %{conn: conn} do
    assert {1, 2} = EdgeDB.query_single!(conn, "SELECT (<int64>$0, <int64>$1)", [1, 2])
  end

  test "encoding nil as valid argument", %{conn: conn} do
    assert set = %EdgeDB.Set{} = EdgeDB.query!(conn, "SELECT <OPTIONAL str>$0", [nil])
    assert EdgeDB.Set.empty?(set)
  end

  test "decoding empty tuple value", %{conn: conn} do
    value = {}
    assert ^value = EdgeDB.query_single!(conn, "SELECT ()")
  end
end
