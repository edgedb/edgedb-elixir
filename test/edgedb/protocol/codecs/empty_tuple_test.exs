defmodule Tests.EdgeDB.Protocol.Codecs.EmtpyTupleTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding empty tuple value", %{conn: conn} do
    value = {}
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT ()")
  end
end
