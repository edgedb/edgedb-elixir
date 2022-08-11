defmodule Tests.EdgeDB.Connection.AuthenticationTest do
  use Tests.Support.EdgeDBCase

  import ExUnit.CaptureLog

  describe "trust authentication with valid params" do
    setup do
      %{
        connection_params: [
          user: "edgedb_trust",
          max_concurrency: 1,
          tls_security: :insecure,
          show_sensitive_data_on_connection_error: true
        ]
      }
    end

    test "connects successfully", context do
      assert {:ok, client} = EdgeDB.start_link(context.connection_params)

      assert 1 = EdgeDB.query_single!(client, "select 1")
    end
  end

  describe "SCRAM authentication with valid params" do
    setup do
      %{
        connection_params: [
          user: "edgedb_scram",
          password: "edgedb_scram_password",
          max_concurrency: 1,
          show_sensitive_data_on_connection_error: true
        ]
      }
    end

    test "login successfully", context do
      assert {:ok, client} = EdgeDB.start_link(context.connection_params)
      assert 1 = EdgeDB.query_single!(client, "select 1")
    end
  end

  describe "SCRAM authentication without password" do
    setup do
      %{
        connection_params: [
          user: "edgedb_scram",
          max_concurrency: 1,
          show_sensitive_data_on_connection_error: true
        ]
      }
    end

    test "disconnects", context do
      assert {:ok, client} = EdgeDB.start_link(context.connection_params)

      assert capture_log(fn ->
               assert {:error, %DBConnection.ConnectionError{}} = EdgeDB.query(client, "select 1")
               assert EdgeDB.Pool.concurrency(client) == 0
             end) =~ "AuthenticationError: authentication failed"
    end
  end

  describe "SCRAM authentication with invalid password" do
    setup do
      %{
        connection_params: [
          username: "edgedb_scram",
          password: "wrong",
          max_concurrency: 1,
          show_sensitive_data_on_connection_error: true
        ]
      }
    end

    test "disconnects", context do
      assert {:ok, client} = EdgeDB.start_link(context.connection_params)

      assert capture_log(fn ->
               assert {:error, %DBConnection.ConnectionError{}} = EdgeDB.query(client, "select 1")
               assert EdgeDB.Pool.concurrency(client) == 0
             end) =~ "AuthenticationError: authentication failed"
    end
  end
end
