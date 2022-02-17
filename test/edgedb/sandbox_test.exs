defmodule Tests.EdgeDB.Pools.SandboxTest do
  use Tests.Support.EdgeDBCase

  @involved_types ~w(
    Ticket
  )

  setup :edgedb_connection

  setup %{conn: conn} do
    for type <- @involved_types do
      query = "DELETE #{type}"
      EdgeDB.query!(conn, query)
    end

    spec =
      EdgeDB.child_spec(
        connection: EdgeDB.Sandbox,
        backoff_type: :stop,
        max_restarts: 0,
        show_sensitive_data_on_connection_error: true
      )

    spec = %{spec | id: "sandbox_edgedb_connection"}
    {:ok, sandbox_conn} = start_supervised(spec)
    EdgeDB.Sandbox.initialize(sandbox_conn)

    opts = EdgeDB.Connection.Config.connect_opts([])

    on_exit(fn ->
      {:ok, conn} = EdgeDB.start_link(opts)
      Process.unlink(conn)

      for type <- @involved_types do
        query = "SELECT count(#{type})"
        assert EdgeDB.query_required_single!(conn, query) == 0
      end

      Process.exit(conn, :kill)
    end)

    %{conn: sandbox_conn}
  end

  describe "EdgeDB.Sandbox" do
    test "doesn't apply transactions from wrapped connections", %{conn: conn} do
      EdgeDB.query!(conn, "INSERT Ticket { number := 1 }")
      assert EdgeDB.query_required_single!(conn, "SELECT Ticket { number } LIMIT 1")[:number] == 1
    end

    test "works with EdgeDB.transaction/3", %{conn: conn} do
      {:ok, _result} =
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query!(conn, "INSERT Ticket { number := 1 }")
        end)

      assert EdgeDB.query_required_single!(conn, "SELECT Ticket { number } LIMIT 1")[:number] == 1
    end

    test "works with EdgeDB.subtransaction/2", %{conn: conn} do
      {:ok, _result} =
        EdgeDB.transaction(conn, fn tx_conn ->
          {:ok, _result} =
            EdgeDB.subtransaction(tx_conn, fn subtx_conn1 ->
              {:ok, _result} =
                EdgeDB.subtransaction(subtx_conn1, fn subtx_conn2 ->
                  EdgeDB.query!(subtx_conn2, "INSERT Ticket { number := 1 }")
                end)
            end)

          :ok
        end)

      assert EdgeDB.query_required_single!(conn, "SELECT Ticket { number } LIMIT 1")[:number] == 1
    end
  end

  describe "EdgeDB.Sandbox.clean/1" do
    test "explicitly rollbacks transaction", %{conn: conn} do
      {:ok, _result} =
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query!(conn, "INSERT Ticket { number := 1 }")
        end)

      assert EdgeDB.query_required_single!(conn, "SELECT Ticket { number } LIMIT 1")[:number] == 1

      EdgeDB.Sandbox.clean(conn)

      refute EdgeDB.query_single!(conn, "SELECT Ticket { number } LIMIT 1")
    end
  end
end
