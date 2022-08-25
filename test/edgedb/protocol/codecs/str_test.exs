defmodule Tests.EdgeDB.Protocol.Codecs.StrTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding std::str value", %{client: client} do
    value = "Harry Potter and the Sorcerer's Stone"

    assert ^value =
             EdgeDB.query_single!(client, "select <str>\"Harry Potter and the Sorcerer's Stone\"")
  end

  test "encoding std::str value", %{client: client} do
    value = "Harry Potter and the Sorcerer's Stone"
    assert ^value = EdgeDB.query_single!(client, "select <str>$0", [value])
  end

  test "error when passing non str as std::str argument", %{client: client} do
    value = 42

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(client, "select <str>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new("value can not be encoded as std::str: #{inspect(value)}")
  end
end
