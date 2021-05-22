defmodule Tests.EdgeDB.Protocol.Codecs.LocalDateTimeTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding cal::local_datetime value", %{conn: conn} do
    value = ~N[2019-05-06 12:00:00]

    assert {:ok, ^value} =
             EdgeDB.query_one(conn, "SELECT <cal::local_datetime>'2019-05-06T12:00'")
  end

  test "encoding cal::local_datetime value", %{conn: conn} do
    value = ~N[2019-05-06 12:00:00Z]

    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <cal::local_datetime>$0", [value])
  end
end
