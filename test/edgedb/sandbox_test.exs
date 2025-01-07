defmodule Tests.EdgeDB.Pools.SandboxTest do
  use Tests.Support.EdgeDBCase

  @involved_types ~w(
    v1::Ticket
  )

  setup :edgedb_client

  setup %{client: client} do
    for type <- @involved_types do
      query = "delete #{type}"
      EdgeDB.query!(client, query)
    end

    spec =
      EdgeDB.child_spec(
        connection: EdgeDB.Sandbox,
        tls_security: :insecure,
        show_sensitive_data_on_connection_error: true
      )

    spec = %{spec | id: "sandbox_edgedb_client"}
    {:ok, sandbox_client} = start_supervised(spec)
    EdgeDB.Sandbox.initialize(sandbox_client)

    on_exit(fn ->
      Tests.Support.EdgeDBCase.setup_stubs_fallbacks(nil)

      {:ok, client} = EdgeDB.start_link(max_concurrency: 1, tls_security: :insecure)
      Process.unlink(client)

      for type <- @involved_types do
        query = "select count(#{type})"
        assert EdgeDB.query_required_single!(client, query) == 0
      end

      Process.exit(client, :kill)
    end)

    %{client: sandbox_client}
  end

  describe "EdgeDB.Sandbox" do
    test "doesn't apply transactions from wrapped connections", %{client: client} do
      EdgeDB.query!(client, "insert v1::Internal { value := 1 }")

      assert EdgeDB.query_required_single!(
               client,
               "select v1::Internal { value } limit 1"
             )[:value] == 1
    end

    test "works with EdgeDB.transaction/3", %{client: client} do
      {:ok, _result} =
        EdgeDB.transaction(client, fn client ->
          EdgeDB.query!(client, "insert v1::Internal { value := 1 }")
        end)

      assert EdgeDB.query_required_single!(
               client,
               "select v1::Internal { value } limit 1"
             )[:value] == 1
    end
  end

  describe "EdgeDB.Sandbox.clean/1" do
    test "explicitly rollbacks transaction", %{client: client} do
      {:ok, _result} =
        EdgeDB.transaction(client, fn client ->
          EdgeDB.query!(client, "insert v1::Internal { value := 1 }")
        end)

      assert EdgeDB.query_required_single!(
               client,
               "select v1::Internal { value } limit 1"
             )[:value] == 1

      EdgeDB.Sandbox.clean(client)

      refute EdgeDB.query_single!(client, "select v1::Internal { value } limit 1")
    end
  end
end
