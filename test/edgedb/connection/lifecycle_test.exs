defmodule Tests.EdgeDB.Connection.LifecycleTest do
  use Tests.Support.EdgeDBCase

  setup do
    Process.flag(:trap_exit, true)

    %{
      connection_params: [
        user: "edgedb_trust",
        backoff_type: :stop,
        max_restarts: 0,
        show_sensitive_data_on_connection_error: true
      ]
    }
  end

  describe "EdgeDB.Connection stops" do
    test "when unable to connect to TCP socket", context do
      {:ok, conn} =
        context.connection_params
        |> Keyword.put(:port, 4242)
        |> EdgeDB.start_link()

      assert_receive {:EXIT, ^conn, :killed}, 500
    end

    test "when unable to connect to database", context do
      {:ok, conn} =
        context.connection_params
        |> Keyword.put(:database, "wrong_db")
        |> EdgeDB.start_link()

      assert_receive {:EXIT, ^conn, :killed}, 500
    end
  end
end
