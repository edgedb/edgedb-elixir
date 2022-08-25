defmodule Tests.EdgeDB.Protocol.Codecs.BytesTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding std::bytes value", %{client: client} do
    value = <<16, 13, 2, 42>>
    assert ^value = EdgeDB.query_single!(client, "select <bytes>b\"\x10\x0d\x02\x2a\"")
  end

  test "encoding std::bytes value", %{client: client} do
    value = <<16, 13, 2, 42>>
    assert ^value = EdgeDB.query_single!(client, "select <bytes>$0", [value])
  end

  test "error when passing non bytes as std::bytes argument", %{client: client} do
    value = 42

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(client, "select <bytes>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new("value can not be encoded as std::bytes: #{inspect(value)}")
  end
end
