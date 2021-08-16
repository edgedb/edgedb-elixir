defmodule Tests.EdgeDB.Protocol.Codecs.ArrayTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding array value", %{conn: conn} do
    value = [16, 13, 2]
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT [16, 13, 2]")
  end

  test "encoding array value", %{conn: conn} do
    value = [16, 13, 2]
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <array<int64>>$0", [value])
  end
end
