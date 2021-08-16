defmodule Tests.EdgeDB.Connection.AuthenticationTest do
  use EdgeDB.Case

  describe "trust authentication with valid params" do
    setup do
      %{connection_params: [user: "edgedb_trust"]}
    end

    test "connects successfully", context do
      assert {:ok, conn} = EdgeDB.start_link(context.connection_params)

      assert 1 = EdgeDB.query_single!(conn, "SELECT 1")
    end
  end

  describe "SCRAM authentication with valid params" do
    setup do
      %{
        connection_params: [
          user: "edgedb_scram",
          password: "edgedb"
        ]
      }
    end

    test "login successfully", context do
      assert {:ok, conn} = EdgeDB.start_link(context.connection_params)

      assert 1 = EdgeDB.query_single!(conn, "SELECT 1")
    end
  end

  describe "SCRAM authentication without password" do
    setup do
      Process.flag(:trap_exit, true)

      %{
        connection_params: [
          user: "edgedb_scram",
          backoff_type: :stop
        ]
      }
    end

    test "disconnects", context do
      assert {:ok, conn} = EdgeDB.start_link(context.connection_params)

      assert_receive {:EXIT, ^conn, :killed}, 500
    end
  end

  describe "SCRAM authentication with invalid password" do
    setup do
      Process.flag(:trap_exit, true)

      %{
        connection_params: [
          username: "edgedb_scram",
          password: "wrong",
          backoff_type: :stop
        ]
      }
    end

    test "disconnects", context do
      assert {:ok, conn} = EdgeDB.start_link(context.connection_params)

      assert_receive {:EXIT, ^conn, :killed}, 500
    end
  end
end
