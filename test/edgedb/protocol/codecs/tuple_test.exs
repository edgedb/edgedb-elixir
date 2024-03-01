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

  describe "encoding tuple value" do
    skip_before(version: 3, scope: :describe)

    test "as named query argument", %{client: client} do
      value = {1, "string", true, 1.0}

      assert ^value =
               EdgeDB.query_single!(client, "select <tuple<int32, str, bool, float32>>$arg", arg: value)
    end

    test "as optional named query argument", %{client: client} do
      result =
        EdgeDB.query_single!(client, "select <optional tuple<int32, str, bool, float32>>$arg", arg: nil)

      assert is_nil(result)
    end

    test "as positional query argument", %{client: client} do
      value = {1, "string", true, 1.0}

      assert ^value =
               EdgeDB.query_single!(client, "select <tuple<int32, str, bool, float32>>$0", [value])
    end

    test "as optional positional query argument", %{client: client} do
      result =
        EdgeDB.query_single!(client, "select <optional tuple<int32, str, bool, float32>>$0", [nil])

      assert is_nil(result)
    end
  end
end
