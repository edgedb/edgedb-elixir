defmodule Tests.EdgeDB.Protocol.Codecs.LocalDateTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding cal::local_date value", %{client: client} do
    value = ~D[2019-05-06]

    assert ^value = EdgeDB.query_single!(client, "select <cal::local_date>'2019-05-06'")
  end

  test "encoding cal::local_date value", %{client: client} do
    value = ~D[2019-05-06]

    assert ^value = EdgeDB.query_single!(client, "select <cal::local_date>$0", [value])
  end
end
