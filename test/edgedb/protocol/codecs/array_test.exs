defmodule Tests.EdgeDB.Protocol.Codecs.ArrayTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding array value", %{client: client} do
    value = [16, 13, 2]
    assert ^value = EdgeDB.query_single!(client, "select [16, 13, 2]")
  end

  test "encoding array value", %{client: client} do
    value = [16, 13, 2]
    assert ^value = EdgeDB.query_single!(client, "select <array<int64>>$0", [value])
  end
end
