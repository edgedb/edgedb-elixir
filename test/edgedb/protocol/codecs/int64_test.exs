defmodule Tests.EdgeDB.Protocol.Codecs.Int64Test do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding std::int64 value", %{conn: conn} do
    value = 1
    assert ^value = EdgeDB.query_single!(conn, "SELECT <int64>1")
  end

  test "encoding std::int64 value", %{conn: conn} do
    value = 1
    assert ^value = EdgeDB.query_single!(conn, "SELECT <int64>$0", [1])
  end

  test "error when passing non-number as std::int64 argument", %{conn: conn} do
    value = 1.0

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <int64>$0", [value])
      end

    assert exc ==
             EdgeDB.Error.invalid_argument_error(
               "value can not be encoded as std::int64: #{inspect(value)}"
             )
  end

  test "error when passing too large number as std::int64 argument", %{conn: conn} do
    value = 0x8000000000000000

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <int64>$0", [value])
      end

    assert exc ==
             EdgeDB.Error.invalid_argument_error(
               "value can not be encoded as std::int64: #{inspect(value)}"
             )
  end

  test "error when passing too small number as std::int64 argument", %{conn: conn} do
    value = -0x8000000000000001

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <int64>$0", [value])
      end

    assert exc ==
             EdgeDB.Error.invalid_argument_error(
               "value can not be encoded as std::int64: #{inspect(value)}"
             )
  end
end
