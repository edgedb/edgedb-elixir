defmodule Tests.EdgeDB.Connection.AuthenticationTest do
  use EdgeDB.Case

  @trust_params [
    user: "edgedb_trust"
  ]
  @scram_params [
    user: "edgedb_scram",
    password: "edgedb"
  ]

  test "login when authentication configured to TRUST" do
    assert {:ok, conn} = EdgeDB.start_link(@trust_params)

    assert {:ok, 1} = EdgeDB.query_single(conn, "SELECT 1")
  end

  test "login when authentication configured to SCRAM" do
    assert {:ok, conn} = EdgeDB.start_link(@scram_params)

    assert {:ok, 1} = EdgeDB.query_single(conn, "SELECT 1")
  end
end
