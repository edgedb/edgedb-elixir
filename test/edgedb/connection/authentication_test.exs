defmodule Tests.EdgeDB.Connection.AuthenticationTest do
  use Tests.Support.EdgeDBCase

  describe "trust authentication with valid params" do
    setup do
      %{
        connection_params: [
          user: "edgedb_trust",
          max_restarts: 0,
          show_sensitive_data_on_connection_error: true
        ]
      }
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
          password: "edgedb_scram_password",
          max_restarts: 0,
          show_sensitive_data_on_connection_error: true
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
          backoff_type: :stop,
          max_restarts: 0,
          show_sensitive_data_on_connection_error: true
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
          backoff_type: :stop,
          max_restarts: 0,
          show_sensitive_data_on_connection_error: true
        ]
      }
    end

    test "disconnects", context do
      assert {:ok, conn} = EdgeDB.start_link(context.connection_params)

      assert_receive {:EXIT, ^conn, :killed}, 500
    end
  end
end
