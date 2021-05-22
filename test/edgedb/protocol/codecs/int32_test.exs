defmodule Tests.EdgeDB.Protocol.Codecs.Int32Test do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Errors

  setup :edgedb_connection

  test "decoding std::int32 value", %{conn: conn} do
    value = 1
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <int32>1")
  end

  test "encoding std::int32 argument", %{conn: conn} do
    value = 1
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <int32>$0", [1])
  end

  test "error when passing non-number as std::int32 argument", %{conn: conn} do
    value = 1.0

    assert_raise Errors.InvalidArgumentError, "unable to encode #{value} as std::int32", fn ->
      EdgeDB.query_one(conn, "SELECT <int32>$0", [value])
    end
  end

  test "error when passing too large number as std::int32 argument", %{conn: conn} do
    value = 0x80000000

    assert_raise Errors.InvalidArgumentError, "unable to encode #{value} as std::int32", fn ->
      EdgeDB.query_one(conn, "SELECT <int32>$0", [value])
    end
  end

  test "error when passing too small number as std::int32 argument", %{conn: conn} do
    value = -0x80000001

    assert_raise Errors.InvalidArgumentError, "unable to encode #{value} as std::int32", fn ->
      EdgeDB.query_one(conn, "SELECT <int32>$0", [value])
    end
  end
end
