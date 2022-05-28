defmodule Tests.EdgeDB.Connection.QueriesTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "connection uses already prepared query from queries cache", %{conn: conn} do
    EdgeDB.query(conn, "select 1")
    {:ok, {%EdgeDB.Query{cached: true}, _r}} = EdgeDB.query(conn, "select 1", [], raw: true)
  end

  test "connection handles optimisic execute flow for prepared query with empty results", %{
    conn: conn
  } do
    EdgeDB.query(conn, "select <str>{}")
    {:ok, {%EdgeDB.Query{cached: true}, _r}} = EdgeDB.query(conn, "select <str>{}", [], raw: true)
  end

  test "result requirement is saved in queries cache", %{conn: conn} do
    assert is_nil(EdgeDB.query_single!(conn, "select User limit 1"))

    assert_raise EdgeDB.Error, ~r/expected result/, fn ->
      EdgeDB.query_required_single!(conn, "select User limit 1")
    end

    assert is_nil(EdgeDB.query_single!(conn, "select User limit 1"))
  end
end
