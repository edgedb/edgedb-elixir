defmodule Tests.EdgeDB.Protocol.Codecs.ScalarTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding custom scalar value", %{client: client} do
    value = "value"
    assert ^value = EdgeDB.query_single!(client, "select <v1::short_str>'value'")
  end

  test "encoding as custom scalar value", %{client: client} do
    value = "value"
    assert ^value = EdgeDB.query_single!(client, "select <v1::short_str>$0", [value])
  end
end
