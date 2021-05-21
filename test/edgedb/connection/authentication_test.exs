defmodule EdgeDB.Tests.Connection.AuthenticationTest do
  use ExUnit.Case

  @trust_params [
    username: "edgedb_trust"
  ]
  @scram_params [
    username: "edgedb_scram",
    password: "edgedb"
  ]
  # TODO: replace with parsing from file
  @common_params [port: 10_700]

  test "login when authentication configured to TRUST" do
    assert {:ok, conn} =
             @trust_params
             |> Keyword.merge(@common_params)
             |> EdgeDB.start_link()

    assert {:ok, 1} = EdgeDB.query_one(conn, "SELECT 1")
  end

  test "login when authentication configured to SCRAM" do
    assert {:ok, conn} =
             @scram_params
             |> Keyword.merge(@common_params)
             |> EdgeDB.start_link()

    assert {:ok, 1} = EdgeDB.query_one(conn, "SELECT 1")
  end
end
