defmodule Tests.EdgeDB.Protocol.Codecs.DateTimeTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding std::datetime value", %{conn: conn} do
    value = ~U[2019-05-06 12:00:00Z]

    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <datetime>'2019-05-06T12:00+00:00'")
  end

  test "encoding std::datetime value", %{conn: conn} do
    value = ~U[2019-05-06 12:00:00Z]

    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <datetime>$0", [value])
  end
end
