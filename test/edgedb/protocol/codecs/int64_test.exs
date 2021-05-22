defmodule Tests.EdgeDB.Protocol.Codecs.Int64Test do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Errors

  setup :edgedb_connection

  test "decoding std::int64 value", %{conn: conn} do
    value = 1
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <int64>1")
  end

  test "encoding std::int64 value", %{conn: conn} do
    value = 1
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <int64>$0", [1])
  end

  test "error when passing non-number as std::int64 argument", %{conn: conn} do
    value = 1.0

    assert_raise Errors.InvalidArgumentError, "unable to encode #{value} as std::int64", fn ->
      EdgeDB.query_one(conn, "SELECT <int64>$0", [value])
    end
  end

  test "error when passing too large number as std::int64 argument", %{conn: conn} do
    value = 0x8000000000000000

    assert_raise Errors.InvalidArgumentError, "unable to encode #{value} as std::int64", fn ->
      EdgeDB.query_one(conn, "SELECT <int64>$0", [value])
    end
  end

  test "error when passing too small number as std::int64 argument", %{conn: conn} do
    value = -0x8000000000000001

    assert_raise Errors.InvalidArgumentError, "unable to encode #{value} as std::int64", fn ->
      EdgeDB.query_one(conn, "SELECT <int64>$0", [value])
    end
  end
end
