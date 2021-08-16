defmodule Tests.EdgeDB.Protocol.Codecs.BoolTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Error

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
      assert_raise Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <bool>$0", [value])
      end

    assert exc == Error.invalid_argument_error("unable to encode #{value} as std::bool")
  end
end
