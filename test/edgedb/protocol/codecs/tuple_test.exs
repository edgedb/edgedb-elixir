defmodule Tests.EdgeDB.Protocol.Codecs.TupleTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding tuple value", %{conn: conn} do
    value = {1, "string", true, 1.0}
    assert ^value = EdgeDB.query_single!(conn, "select (1, \"string\", true, 1.0)")
  end

  test "decoding empty tuple value", %{conn: conn} do
    value = {}
    assert ^value = EdgeDB.query_single!(conn, "select ()")
  end
end
