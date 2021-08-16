defmodule Tests.EdgeDB.Protocol.Codecs.Flaot32Test do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Error

  setup :edgedb_connection

  test "decoding std::float32 value", %{conn: conn} do
    value = 0.5
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <float32>0.5")
  end

  test "decoding NaN as std::float32 value", %{conn: conn} do
    value = :nan
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <float32>'NaN'")
  end

  test "decoding infinity as std::float32 value", %{conn: conn} do
    value = :infinity
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <float32>'inf'")
  end

  test "decoding -infinity as std::float32 value", %{conn: conn} do
    value = :negative_infinity
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <float32>'-inf'")
  end

  test "encoding std::float32 argument", %{conn: conn} do
    value = 1.0
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <float32>$0", [value])
  end

  test "encoding NaN as std::float32 argument", %{conn: conn} do
    value = :nan
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <float32>$0", [value])
  end

  test "encoding infinity as std::float32 argument", %{conn: conn} do
    value = :infinity
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <float32>$0", [value])
  end

  test "encoding -infinity as std::float32 argument", %{conn: conn} do
    value = :negative_infinity
    assert {:ok, ^value} = EdgeDB.query_single(conn, "SELECT <float32>$0", [value])
  end

  test "error when passing non-number as std::float32 argument", %{conn: conn} do
    value = "something"

    exc =
      assert_raise Error, fn ->
        EdgeDB.query_single(conn, "SELECT <float32>$0", [value])
      end

    assert exc == Error.invalid_argument_error("unable to encode \"something\" as std::float32")
  end
end
