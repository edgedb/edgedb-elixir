defmodule Tests.EdgeDB.Protocol.Codecs.BoolTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding std::bool value", %{client: client} do
    value = true

    assert {:ok, ^value} = EdgeDB.query_single(client, "select <bool>true")
  end

  test "encoding std::bool value", %{client: client} do
    value = false
    assert {:ok, ^value} = EdgeDB.query_single(client, "select <bool>$0", [value])
  end

  test "error when passing non bool as std::bool argument", %{client: client} do
    value = 42

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(client, "select <bool>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new("value can not be encoded as std::bool: #{inspect(value)}")
  end
end
