defmodule Tests.EdgeDB.Protocol.Codecs.TupleTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding tuple value", %{client: client} do
    value = {1, "string", true, 1.0}
    assert ^value = EdgeDB.query_single!(client, "select (1, \"string\", true, 1.0)")
  end

  test "decoding empty tuple value", %{client: client} do
    value = {}
    assert ^value = EdgeDB.query_single!(client, "select ()")
  end
end
