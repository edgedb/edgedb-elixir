defmodule Tests.EdgeDB.Protocol.Codecs.Int16Test do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding std::int16 number", %{conn: conn} do
    value = 1
    assert ^value = EdgeDB.query_single!(conn, "select <int16>1")
  end

  test "encoding std::int16 argument", %{conn: conn} do
    value = 1
    assert ^value = EdgeDB.query_single!(conn, "select <int16>$0", [1])
  end

  test "error when passing non-number as std::int16 argument", %{conn: conn} do
    value = 1.0

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "select <int16>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as std::int16: #{inspect(value)}"
             )
  end

  test "error when passing too large number as std::int16 argument", %{conn: conn} do
    value = 0x8000

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "select <int16>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as std::int16: #{inspect(value)}"
             )
  end

  test "error when passing too small number as std::int16 argument", %{conn: conn} do
    value = -0x8001

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "select <int16>$0", [value])
      end

    assert exc ==
             EdgeDB.InvalidArgumentError.new(
               "value can not be encoded as std::int16: #{inspect(value)}"
             )
  end
end
