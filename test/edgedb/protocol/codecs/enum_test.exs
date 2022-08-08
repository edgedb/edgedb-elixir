defmodule Tests.EdgeDB.Protocol.Codecs.EnumTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding enum value", %{client: client} do
    value = "Green"
    assert ^value = EdgeDB.query_single!(client, "select <Color>'Green'")
  end

  test "encoding string to enum value", %{client: client} do
    value = "Green"
    assert ^value = EdgeDB.query_single!(client, "select <Color>$0", [value])
  end

  test "error when encoding not member element to enum value", %{client: client} do
    value = "White"

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(client, "select <Color>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as enum: not enum member: #{inspect(value)}"
             )
  end
end
