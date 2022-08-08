defmodule Tests.EdgeDB.Protocol.Codecs.LocalDateTimeTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding cal::local_datetime value", %{client: client} do
    value = ~N[2019-05-06 12:00:00]

    assert ^value = EdgeDB.query_single!(client, "select <cal::local_datetime>'2019-05-06T12:00'")
  end

  test "encoding cal::local_datetime value", %{client: client} do
    value = ~N[2019-05-06 12:00:00Z]

    assert ^value = EdgeDB.query_single!(client, "select <cal::local_datetime>$0", [value])
  end
end
