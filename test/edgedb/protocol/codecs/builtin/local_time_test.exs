defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.LocalTimeTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding cal::local_time value", %{conn: conn} do
    value = ~T[12:10:00]

    assert ^value = EdgeDB.query_single!(conn, "SELECT <cal::local_time>'12:10'")
  end

  test "encoding cal::local_time value", %{conn: conn} do
    value = ~T[12:10:00]

    assert ^value = EdgeDB.query_single!(conn, "SELECT <cal::local_time>$0", [value])
  end
end
