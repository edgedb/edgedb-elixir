defmodule Tests.EdgeDB.Connection.QueriesTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "connection uses already prepared query from queries cache", %{conn: conn} do
    EdgeDB.query(conn, "SELECT 1")
    {:ok, {%EdgeDB.Query{cached?: true}, _r}} = EdgeDB.query(conn, "SELECT 1", [], raw: true)
  end
end
