defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.TupleTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding tuple value", %{conn: conn} do
    value = {1, "string", true, 1.0}
    assert ^value = EdgeDB.query_single!(conn, "SELECT (1, \"string\", true, 1.0)")
  end
end
