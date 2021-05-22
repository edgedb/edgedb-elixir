defmodule Tests.EdgeDB.Protocol.Codecs.SetTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding set value", %{conn: conn} do
    value = EdgeDB.Set.new([1, 2, 3])
    assert {:ok, ^value} = EdgeDB.query(conn, "SELECT {1, 2, 3}")
  end
end
