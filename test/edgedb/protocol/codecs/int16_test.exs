defmodule Tests.EdgeDB.Protocol.Codecs.Int16Test do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Errors

  setup :edgedb_connection

  test "decoding std::int16 number", %{conn: conn} do
    value = 1
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <int16>1")
  end

  test "encoding std::int16 argument", %{conn: conn} do
    value = 1
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <int16>$0", [1])
  end

  test "error when passing non-number as std::int16 argument", %{conn: conn} do
    value = 1.0

    assert_raise Errors.InvalidArgumentError, "unable to encode #{value} as std::int16", fn ->
      EdgeDB.query_one(conn, "SELECT <int16>$0", [value])
    end
  end

  test "error when passing too large number as std::int16 argument", %{conn: conn} do
    value = 0x8000

    assert_raise Errors.InvalidArgumentError, "unable to encode #{value} as std::int16", fn ->
      EdgeDB.query_one(conn, "SELECT <int16>$0", [value])
    end
  end

  test "error when passing too small number as std::int16 argument", %{conn: conn} do
    value = -0x8001

    assert_raise Errors.InvalidArgumentError, "unable to encode #{value} as std::int16", fn ->
      EdgeDB.query_one(conn, "SELECT <int16>$0", [value])
    end
  end
end
