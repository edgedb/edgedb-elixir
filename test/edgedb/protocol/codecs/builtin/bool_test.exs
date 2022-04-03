defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.BoolTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding std::bool value", %{conn: conn} do
    value = true

    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <bool>true")
  end

  test "encoding std::bool value", %{conn: conn} do
    value = false
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <bool>$0", [value])
  end

  test "error when passing non bool as std::bool argument", %{conn: conn} do
    value = 42

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <bool>$0", [value])
      end

    assert exc ==
             EdgeDB.Error.invalid_argument_error(
               "value can not be encoded as std::bool: #{inspect(value)}"
             )
  end
end
