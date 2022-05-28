defmodule Tests.EdgeDB.Protocol.Codecs.BoolTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding std::bool value", %{conn: conn} do
    value = true

    assert {:ok, ^value} = EdgeDB.query_single(conn, "select <bool>true")
  end

  test "encoding std::bool value", %{conn: conn} do
    value = false
    assert {:ok, ^value} = EdgeDB.query_single(conn, "select <bool>$0", [value])
  end

  test "error when passing non bool as std::bool argument", %{conn: conn} do
    value = 42

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "select <bool>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as std::bool: #{inspect(value)}"
             )
  end
end
