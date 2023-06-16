defmodule Tests.EdgeDB.APITest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  describe "EdgeDB.query/4" do
    test "returns EdgeDB.Set on succesful query", %{client: client} do
      assert {:ok, %EdgeDB.Set{}} = EdgeDB.query(client, "select 1")
    end

    test "returns error on failed query", %{client: client} do
      assert {:error, %EdgeDB.Error{}} =
               EdgeDB.query(client, "select {1, 2, 3}", [], cardinality: :one)
    end
  end

  describe "EdgeDB.query/4 for readonly queries" do
    setup :reconnectable_edgedb_client

    test "retries failed query", %{client: client, socket: socket} do
      EdgeDB.query!(client, "select Ticket")

      :ssl.close(socket)

      test_pid = self()

      assert %EdgeDB.Set{} =
               EdgeDB.query!(client, "select Ticket", [],
                 retry: [
                   network_error: [
                     attempts: 1,
                     backoff: fn attempt ->
                       send(test_pid, {:attempt, attempt})
                       0
                     end
                   ]
                 ]
               )

      assert_receive {:attempt, 1}
    end
  end

  describe "EdgeDB.query_json/4" do
    test "returns decoded JSON on succesful query", %{client: client} do
      assert {:ok, "[{\"number\" : 1}]"} = EdgeDB.query_json(client, "select { number := 1 }")
    end
  end

  describe "EdgeDB.query!/4" do
    test "returns EdgeDB.Set on succesful query", %{client: client} do
      assert %EdgeDB.Set{} = EdgeDB.query!(client, "select 1")
    end

    test "raises error on failed query", %{client: client} do
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query!(client, "select {1, 2, 3}", [], cardinality: :one)
      end
    end
  end

  describe "EdgeDB.query_json!/4" do
    test "returns decoded JSON on succesful query", %{client: client} do
      assert "[{\"number\" : 1}]" = EdgeDB.query_json!(client, "select { number := 1 }")
    end
  end

  describe "EdgeDB.query_single/4" do
    test "returns result on succesful query", %{client: client} do
      assert {:ok, 1} = EdgeDB.query_single(client, "select 1")
    end

    test "raises error on failed query", %{client: client} do
      {:error, %EdgeDB.Error{}} =
        EdgeDB.query_single(client, "select {1, 2, 3}", [], cardinality: :one)
    end
  end

  describe "EdgeDB.query_single!/4" do
    test "returns result on succesful query", %{client: client} do
      assert 1 = EdgeDB.query_single!(client, "select 1")
    end

    test "raises error on failed query", %{client: client} do
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.transaction(client, fn client ->
          EdgeDB.query_single!(client, "select {1, 2, 3}", [], cardinality: :one)
        end)
      end
    end
  end

  describe "EdgeDB.query_required_single/4" do
    test "returns result on succesful query", %{client: client} do
      assert {:ok, 1} = EdgeDB.query_required_single(client, "select 1")
    end

    test "raises error on failed query", %{client: client} do
      {:error, %EdgeDB.Error{}} = EdgeDB.query_required_single(client, "select <int64>{}", [])
    end
  end

  describe "EdgeDB.query_required_single!/4" do
    test "returns result on succesful query", %{client: client} do
      assert 1 = EdgeDB.query_required_single!(client, "select 1")
    end

    test "raises error on failed query", %{client: client} do
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_required_single!(client, "select <int64>{}")
      end
    end
  end

  describe "EdgeDB.query_single_json/4" do
    test "returns decoded JSON on succesful query", %{client: client} do
      assert {:ok, "{\"number\" : 1}"} =
               EdgeDB.query_single_json(client, "select { number := 1 }")
    end

    test "returns JSON null for empty set", %{client: client} do
      assert {:ok, "null"} = EdgeDB.query_single_json(client, "select <int64>{}")
    end
  end

  describe "EdgeDB.query_single_json!/4" do
    test "returns decoded JSON on succesful query", %{client: client} do
      assert "{\"number\" : 1}" = EdgeDB.query_single_json!(client, "select { number := 1 }")
    end
  end

  describe "EdgeDB.query_required_single_json/4" do
    test "returns decoded JSON on succesful query", %{client: client} do
      assert {:ok, "1"} = EdgeDB.query_required_single_json(client, "select 1")
    end
  end

  describe "EdgeDB.query_required_single_json!/4" do
    test "returns decoded JSON on succesful query", %{client: client} do
      assert "1" = EdgeDB.query_required_single_json!(client, "select 1")
    end
  end

  describe "EdgeDB.execute/4" do
    test "executes query", %{client: client} do
      {:error, :rollback} =
        EdgeDB.transaction(client, fn conn ->
          :ok =
            EdgeDB.execute(conn, """
              insert User { image := '', name := 'username1' };
              insert User { image := '', name := 'username2' };
            """)

          EdgeDB.rollback(conn, reason: :rollback)
        end)
    end
  end

  describe "EdgeDB.execute!/4" do
    test "executes query", %{client: client} do
      {:error, :rollback} =
        EdgeDB.transaction(client, fn conn ->
          EdgeDB.execute!(conn, """
            insert User { image := '', name := 'username1' };
            insert User { image := '', name := 'username2' };
          """)

          EdgeDB.rollback(conn, reason: :rollback)
        end)
    end
  end

  describe "EdgeDB.transaction/3" do
    test "commits result if no error occured", %{client: client} do
      assert {:ok, %EdgeDB.Object{id: user_id}} =
               EdgeDB.transaction(client, fn conn ->
                 EdgeDB.query_single!(conn, """
                   insert User { image := '', name := 'username' }
                 """)
               end)

      %EdgeDB.Object{id: ^user_id} =
        EdgeDB.query_required_single!(client, "select User filter .id = <uuid>$0", [user_id])

      EdgeDB.execute!(client, "delete User")
    end

    test "automaticly rollbacks if error occured", %{client: client} do
      assert_raise RuntimeError, fn ->
        EdgeDB.transaction(client, fn conn ->
          EdgeDB.query!(conn, "insert User { image := '', name := 'username' }")
          raise RuntimeError
        end)
      end

      assert EdgeDB.Set.empty?(EdgeDB.query!(client, "select User"))
    end

    test "automaticly rollbacks if error in EdgeDB occured", %{client: client} do
      assert_raise EdgeDB.Error, ~r/violates exclusivity constraint/, fn ->
        EdgeDB.transaction(client, fn conn ->
          EdgeDB.query!(conn, "insert Ticket { number := 1 }")
          EdgeDB.query!(conn, "insert Ticket { number := 1 }")
        end)
      end

      assert EdgeDB.Set.empty?(EdgeDB.query!(client, "select Ticket"))
    end

    test "raises borrow error in case of nested transactions", %{client: client} do
      assert_raise EdgeDB.Error, ~r/borrowed for transaction/, fn ->
        EdgeDB.transaction(client, fn tx_conn1 ->
          EdgeDB.transaction(tx_conn1, fn tx_conn2 ->
            EdgeDB.query!(tx_conn2, "select 1")
          end)
        end)
      end
    end

    test "won't retry on non EdgeDB errors", %{client: client} do
      rule = [
        attempts: 1,
        backoff: fn _attempt ->
          raise RuntimeError, "shouldn't get here"
        end
      ]

      assert_raise RuntimeError, ~r/expected/, fn ->
        EdgeDB.transaction(client, fn _tx_conn -> raise RuntimeError, message: "expected" end,
          retry: [network_error: rule, transaction_conflict: rule]
        )
      end
    end
  end

  describe "EdgeDB.rollback/2" do
    test "rollbacks transaction", %{client: client} do
      {:error, :rollback} =
        EdgeDB.transaction(client, fn client ->
          EdgeDB.query!(client, "insert User { image := '', name := 'username' }")
          EdgeDB.rollback(client, reason: :rollback)
        end)
    end
  end

  describe "EdgeDB.as_readonly/2" do
    setup %{client: client} do
      %{client: EdgeDB.as_readonly(client)}
    end

    test "configures connection that will fail for non-readonly requests", %{client: client} do
      exc =
        assert_raise EdgeDB.Error, fn ->
          EdgeDB.query!(client, "insert Ticket")
        end

      assert exc.type == EdgeDB.DisabledCapabilityError
    end

    test "configures connection that will fail for non-readonly requests in transaction", %{
      client: client
    } do
      exc =
        assert_raise EdgeDB.Error, fn ->
          EdgeDB.transaction(client, fn client ->
            EdgeDB.query!(client, "insert Ticket")
          end)
        end

      assert exc.type == EdgeDB.DisabledCapabilityError
    end

    test "configures connection that executes readonly requests", %{client: client} do
      assert 1 == EdgeDB.query_single!(client, "select 1")
    end

    test "configures connection that executes readonly requests in transaction", %{
      client: client
    } do
      assert {:ok, 1} ==
               EdgeDB.transaction(client, fn client ->
                 EdgeDB.query_single!(client, "select 1")
               end)
    end
  end

  describe "EdgeDB.with_transaction_options/2" do
    test "accepts options for changing transaction", %{client: client} do
      exc =
        assert_raise EdgeDB.Error, ~r/read-only transaction/, fn ->
          client
          |> EdgeDB.with_transaction_options(readonly: true)
          |> EdgeDB.transaction(fn client ->
            EdgeDB.query!(client, "insert Ticket{ number := 1 }")
          end)
        end

      assert exc.type == EdgeDB.TransactionError
    end
  end

  describe "EdgeDB.with_retry_options/2" do
    test "accepts options for changing retries in transactions for transactions conflicts", %{
      client: client
    } do
      pid = self()

      exc =
        assert_raise EdgeDB.Error, ~r/test error/, fn ->
          client
          |> EdgeDB.with_retry_options(
            transaction_conflict: [
              attempts: 10,
              backoff: fn attempt ->
                send(pid, {:attempt, attempt})
                10
              end
            ]
          )
          |> EdgeDB.transaction(fn client ->
            EdgeDB.query!(client, "insert Ticket{ number := 1 }")
            raise EdgeDB.TransactionConflictError.new("test error")
          end)
        end

      assert EdgeDB.Set.empty?(EdgeDB.query!(client, "select Ticket"))

      assert exc.type == EdgeDB.TransactionConflictError

      for attempt <- 1..5 do
        assert_receive {:attempt, ^attempt}
      end
    end

    test "accepts options for changing retries in transactions for network errors", %{
      client: client
    } do
      test_pid = self()

      exc =
        assert_raise EdgeDB.Error, ~r/test error/, fn ->
          client
          |> EdgeDB.with_retry_options(
            network_error: [
              backoff: fn attempt ->
                send(test_pid, {:attempt, attempt})
                10
              end
            ]
          )
          |> EdgeDB.transaction(fn client ->
            EdgeDB.query!(client, "insert Ticket{ number := 1 }")
            raise EdgeDB.ClientConnectionFailedTemporarilyError.new("test error")
          end)
        end

      assert EdgeDB.Set.empty?(EdgeDB.query!(client, "select Ticket"))

      assert exc.type == EdgeDB.ClientConnectionFailedTemporarilyError

      for attempt <- 1..3 do
        assert_receive {:attempt, ^attempt}
      end
    end
  end

  describe "EdgeDB.with_default_module/2" do
    skip_before(version: 2, scope: :describe)

    setup %{client: client} do
      %{client: EdgeDB.with_default_module(client, "schema")}
    end

    test "passes module to EdgeDB", %{client: client} do
      assert %EdgeDB.Object{} =
               EdgeDB.query_required_single!(client, """
                  select ObjectType
                  filter .name = 'std::BaseObject'
                  limit 1
               """)
    end

    test "without argument removes module from passing to EdgeDB", %{client: client} do
      assert_raise EdgeDB.Error, ~r/'default::ObjectType' does not exist/, fn ->
        client
        |> EdgeDB.with_default_module()
        |> EdgeDB.query_required_single!("""
          select ObjectType
          filter .name = 'std::BaseObject'
          limit 1
        """)
      end
    end
  end

  describe "EdgeDB.with_module_aliases/2" do
    skip_before(version: 2, scope: :describe)

    setup %{client: client} do
      %{
        client:
          EdgeDB.with_module_aliases(client, %{"schema_alias" => "schema", "cfg_alias" => "cfg"})
      }
    end

    test "passes aliases to EdgeDB", %{client: client} do
      assert %EdgeDB.Object{} =
               EdgeDB.query_required_single!(client, """
                  select schema_alias::ObjectType
                  filter .name = 'std::BaseObject'
                  limit 1
               """)

      assert %EdgeDB.ConfigMemory{} =
               EdgeDB.query_required_single!(client, "select <cfg_alias::memory>'1B'")
    end
  end

  describe "EdgeDB.without_module_aliases/2" do
    skip_before(version: 2, scope: :describe)

    setup %{client: client} do
      %{
        client:
          EdgeDB.without_module_aliases(client, %{
            "schema_alias" => "schema",
            "cfg_alias" => "cfg"
          })
      }
    end

    test "removes aliases from passed to EdgeDB", %{client: client} do
      assert_raise EdgeDB.Error, ~r/type 'cfg_alias::memory' does not exist/, fn ->
        client
        |> EdgeDB.without_module_aliases(["cfg_alias"])
        |> EdgeDB.query_required_single!("select <cfg_alias::memory>'1B'")
      end
    end
  end

  describe "EdgeDB.with_config/2" do
    skip_before(version: 2, scope: :describe)

    setup %{client: client} do
      # 48:45:07:6
      duration = Timex.Duration.from_microseconds(175_507_600_000)

      %{
        client: EdgeDB.with_config(client, %{query_execution_timeout: duration}),
        duration: duration
      }
    end

    test "passes config to EdgeDB", %{client: client, duration: duration} do
      config_object =
        EdgeDB.query_required_single!(client, """
          select cfg::Config {
            query_execution_timeout
          }
          limit 1
        """)

      assert config_object[:query_execution_timeout] == duration
    end
  end

  describe "EdgeDB.without_config/2" do
    skip_before(version: 2, scope: :describe)

    setup %{client: client} do
      # 48:45:07:6
      duration = Timex.Duration.from_microseconds(175_507_600_000)

      %{client: EdgeDB.with_config(client, %{query_execution_timeout: duration})}
    end

    test "removes config keys from passed to EdgeDB", %{client: client} do
      config_object =
        client
        |> EdgeDB.without_config([:query_execution_timeout])
        |> EdgeDB.query_required_single!("select cfg::Config { query_execution_timeout } limit 1")

      assert config_object[:query_execution_timeout] == Timex.Duration.from_microseconds(0)
    end
  end

  describe "EdgeDB.with_globals/2" do
    skip_before(version: 2, scope: :describe)

    setup %{client: client} do
      current_user = "some_username"

      %{
        client: EdgeDB.with_globals(client, %{"current_user" => current_user}),
        current_user: current_user
      }
    end

    test "passes globals to EdgeDB", %{client: client, current_user: current_user} do
      assert current_user == EdgeDB.query_required_single!(client, "select global current_user")
    end
  end

  describe "EdgeDB.without_globals/2" do
    skip_before(version: 2, scope: :describe)

    setup %{client: client} do
      current_user = "some_username"
      %{client: EdgeDB.with_globals(client, %{"current_user" => current_user})}
    end

    test "removes globals from passed to EdgeDB", %{client: client} do
      client = EdgeDB.without_globals(client, ["current_user"])
      refute EdgeDB.query_single!(client, "select global current_user")
    end
  end

  describe "EdgeDB.with_state/2" do
    skip_before(version: 2, scope: :describe)

    setup %{client: client} do
      current_user = "current_user"

      # 48:45:07:6
      duration = Timex.Duration.from_microseconds(175_507_600_000)

      state =
        %EdgeDB.Client.State{}
        |> EdgeDB.Client.State.with_default_module("schema")
        |> EdgeDB.Client.State.with_module_aliases(%{"math_alias" => "math", "cfg_alias" => "cfg"})
        |> EdgeDB.Client.State.with_globals(%{"default::current_user" => current_user})
        |> EdgeDB.Client.State.with_config(%{query_execution_timeout: duration})

      %{
        client: EdgeDB.with_client_state(client, state),
        current_user: current_user,
        duration: duration
      }
    end

    test "passes state to EdgeDB", %{
      client: client,
      current_user: current_user,
      duration: duration
    } do
      object =
        EdgeDB.query_required_single!(client, """
          with
            config := (select cfg_alias::Config limit 1),
            abs_value := math_alias::abs(-1),
            user_object_type := (select ObjectType filter .name = 'default::User' limit 1)
          select {
            current_user := global default::current_user,
            config_query_execution_timeout := config.query_execution_timeout,
            math_abs_value := abs_value,
            user_type := user_object_type { name }
          }
        """)

      assert object[:current_user] == current_user
      assert object[:config_query_execution_timeout] == duration
      assert object[:math_abs_value] == 1
      assert object[:user_type][:name] == "default::User"
    end
  end
end
