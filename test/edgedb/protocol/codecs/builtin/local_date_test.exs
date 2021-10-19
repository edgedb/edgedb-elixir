defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.LocalDateTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding cal::local_date value", %{conn: conn} do
    value = ~D[2019-05-06]

    assert ^value = EdgeDB.query_single!(conn, "SELECT <cal::local_date>'2019-05-06'")
  end

  test "encoding cal::local_date value", %{conn: conn} do
    value = ~D[2019-05-06]

    assert ^value = EdgeDB.query_single!(conn, "SELECT <cal::local_date>$0", [value])
  end
end
