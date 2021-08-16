defmodule Tests.EdgeDB.Protocol.Codecs.TupleTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding tuple value", %{conn: conn} do
    value = {1, "string", true, 1.0}
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT (1, \"string\", true, 1.0)")
  end
end
