defmodule Tests.EdgeDB.Connection.LifecycleTest do
  use Tests.Support.EdgeDBCase

  import ExUnit.CaptureLog

  setup do
    %{
      connection_params: [
        user: "edgedb_trust",
        tls_security: :insecure,
        max_concurrency: 1,
        show_sensitive_data_on_connection_error: true
      ]
    }
  end

  describe "EdgeDB.Connection stops" do
    test "when unable to connect to TCP socket", context do
      {:ok, client} =
        context.connection_params
        |> Keyword.put(:port, 4242)
        |> EdgeDB.start_link()

      assert capture_log(fn ->
               assert {:error, %DBConnection.ConnectionError{}} = EdgeDB.query(client, "select 1")
               assert EdgeDB.Pool.concurrency(client) == 0
             end) =~ "ClientConnectionError: unable to establish connection: :econnrefused"
    end

    test "when unable to connect to database", context do
      {:ok, client} =
        context.connection_params
        |> Keyword.put(:database, "wrong_db")
        |> EdgeDB.start_link()

      assert capture_log(fn ->
               assert {:error, %DBConnection.ConnectionError{}} = EdgeDB.query(client, "select 1")
               assert EdgeDB.Pool.concurrency(client) == 0
             end) =~
               ~r/UnknownDatabaseError: (database|database branch) 'wrong_db' does not exist/
    end
  end
end
