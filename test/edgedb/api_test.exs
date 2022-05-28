defmodule Tests.EdgeDB.APITest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  describe "EdgeDB.query/4" do
    test "returns EdgeDB.Set on succesful query", %{conn: conn} do
      assert {:ok, %EdgeDB.Set{}} = EdgeDB.query(conn, "select 1")
    end

    test "returns error on failed query", %{conn: conn} do
      assert {:error, %EdgeDB.Error{}} =
               EdgeDB.query(conn, "select {1, 2, 3}", [], cardinality: :one)
    end
  end

  describe "EdgeDB.query/4 for readonly queries" do
    setup :reconnectable_edgedb_connection

    test "retries failed query", %{conn: conn, pid: conn_pid} do
      test_pid = self()

      %{
        mod_state: %{
          state: %EdgeDB.Connection.State{
            socket: socket
          }
        }
      } = :sys.get_state(conn_pid)

      EdgeDB.query!(conn, "select Ticket")

      :ssl.close(socket)

      assert %EdgeDB.Set{} =
               EdgeDB.query!(conn, "select Ticket", [],
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
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert {:ok, "[{\"number\" : 1}]"} = EdgeDB.query_json(conn, "select { number := 1 }")
    end
  end

  describe "EdgeDB.query!/4" do
    test "returns EdgeDB.Set on succesful query", %{conn: conn} do
      assert %EdgeDB.Set{} = EdgeDB.query!(conn, "select 1")
    end

    test "raises error on failed query", %{conn: conn} do
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query!(conn, "select {1, 2, 3}", [], cardinality: :one)
      end
    end
  end

  describe "EdgeDB.query_json!/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert "[{\"number\" : 1}]" = EdgeDB.query_json!(conn, "select { number := 1 }")
    end
  end

  describe "EdgeDB.query_single/4" do
    test "returns result on succesful query", %{conn: conn} do
      assert {:ok, 1} = EdgeDB.query_single(conn, "select 1")
    end

    test "raises error on failed query", %{conn: conn} do
      {:error, %EdgeDB.Error{}} =
        EdgeDB.query_single(conn, "select {1, 2, 3}", [], cardinality: :one)
    end
  end

  describe "EdgeDB.query_single!/4" do
    test "returns result on succesful query", %{conn: conn} do
      assert 1 = EdgeDB.query_single!(conn, "select 1")
    end

    test "raises error on failed query", %{conn: conn} do
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query_single!(conn, "select {1, 2, 3}", [], cardinality: :one)
        end)
      end
    end
  end

  describe "EdgeDB.query_required_single/4" do
    test "returns result on succesful query", %{conn: conn} do
      assert {:ok, 1} = EdgeDB.query_required_single(conn, "select 1")
    end

    test "raises error on failed query", %{conn: conn} do
      {:error, %EdgeDB.Error{}} = EdgeDB.query_required_single(conn, "select <int64>{}", [])
    end
  end

  describe "EdgeDB.query_required_single!/4" do
    test "returns result on succesful query", %{conn: conn} do
      assert 1 = EdgeDB.query_required_single!(conn, "select 1")
    end

    test "raises error on failed query", %{conn: conn} do
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_required_single!(conn, "select <int64>{}")
      end
    end
  end

  describe "EdgeDB.query_single_json/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert {:ok, "{\"number\" : 1}"} = EdgeDB.query_single_json(conn, "select { number := 1 }")
    end

    test "returns JSON null for empty set", %{conn: conn} do
      assert {:ok, "null"} = EdgeDB.query_single_json(conn, "select <int64>{}")
    end
  end

  describe "EdgeDB.query_single_json!/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert "{\"number\" : 1}" = EdgeDB.query_single_json!(conn, "select { number := 1 }")
    end
  end

  describe "EdgeDB.query_required_single_json/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert {:ok, "1"} = EdgeDB.query_required_single_json(conn, "select 1")
    end
  end

  describe "EdgeDB.query_required_single_json!/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert "1" = EdgeDB.query_required_single_json!(conn, "select 1")
    end
  end

  describe "EdgeDB.transaction/3" do
    test "commit result if no error occured", %{conn: conn} do
      {:ok, %EdgeDB.Object{id: user_id}} =
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query_single!(conn, "insert User { image := '', name := 'username' }")
        end)

      %EdgeDB.Object{id: ^user_id} =
        EdgeDB.query_single!(conn, "delete User filter .id = <uuid>$0", [user_id])

      assert EdgeDB.Set.empty?(
               EdgeDB.query!(conn, "select User filter .id = <uuid>$0", [user_id])
             )
    end

    test "automaticly rollbacks if error occured", %{conn: conn} do
      assert_raise RuntimeError, fn ->
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query!(conn, "insert User { image := '', name := 'username' }")
          raise RuntimeError
        end)
      end

      assert EdgeDB.Set.empty?(EdgeDB.query!(conn, "select User"))
    end

    test "automaticly rollbacks if error in EdgeDB occured", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/violates exclusivity constraint/, fn ->
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query!(conn, "insert Ticket { number := 1 }")
          EdgeDB.query!(conn, "insert Ticket { number := 1 }")
        end)
      end

      assert EdgeDB.Set.empty?(EdgeDB.query!(conn, "select Ticket"))
    end

    test "nested transactions raises borrow error", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/borrowed for transaction/, fn ->
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.transaction(conn, fn conn ->
            EdgeDB.query!(conn, "select 1")
          end)
        end)
      end
    end

    test "forbids using original connection inside", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/borrowed for transaction/, fn ->
        EdgeDB.transaction(conn, fn _tx_conn ->
          EdgeDB.query!(conn, "select 1")
        end)
      end

      assert "ok" = EdgeDB.query_required_single!(conn, ~s(select "ok"))
    end

    test "won't retry on non EdgeDB errors", %{conn: conn} do
      rule = [
        attempts: 1,
        backoff: fn _attempt ->
          raise RuntimeError, "shouldn't get here"
        end
      ]

      assert_raise RuntimeError, ~r/expected/, fn ->
        EdgeDB.transaction(conn, fn _tx_conn -> raise RuntimeError, message: "expected" end,
          retry: [network_error: rule, transaction_conflict: rule]
        )
      end
    end
  end

  describe "EdgeDB.subtransaction/2" do
    test "allowed only on connections in transactions", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/(already in transaction)|(another subtransaction)/, fn ->
        EdgeDB.subtransaction(conn, fn _subtx_conn ->
          :ok
        end)
      end
    end

    test "rollbacks nested transaction without breaking the outer", %{conn: conn} do
      EdgeDB.transaction(conn, fn tx_conn ->
        assert {:error, :subtx_rollback} =
                 EdgeDB.subtransaction(tx_conn, fn subtx_conn ->
                   EdgeDB.query!(subtx_conn, "insert Ticket{ number := 1 }")

                   assert %EdgeDB.Object{} =
                            EdgeDB.query_required_single!(subtx_conn, "select Ticket limit 1")

                   EdgeDB.rollback(subtx_conn, reason: :subtx_rollback)
                 end)

        assert 0 == EdgeDB.query_required_single!(tx_conn, "select count(Ticket)")
      end)
    end

    test "not rollbacked changes from inner subtransactions seen to outer and to main transaction",
         %{conn: conn} do
      EdgeDB.transaction(conn, fn tx_conn ->
        assert {:ok, :ok} =
                 EdgeDB.subtransaction(tx_conn, fn subtx_conn_1 ->
                   {:ok, %EdgeDB.Set{}} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "insert Ticket{ number := 1 }")
                     end)

                   assert 1 == EdgeDB.query_required_single!(subtx_conn_1, "select count(Ticket)")

                   {:error, :rollback} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "insert Ticket{ number := 2 }")
                       EdgeDB.rollback(subtx_conn_2)
                     end)

                   assert 1 == EdgeDB.query_required_single!(subtx_conn_1, "select count(Ticket)")

                   {:ok, %EdgeDB.Set{}} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "insert Ticket{ number := 3 }")
                     end)

                   assert 2 == EdgeDB.query_required_single!(subtx_conn_1, "select count(Ticket)")

                   :ok
                 end)

        assert 2 == EdgeDB.query_required_single!(tx_conn, "select count(Ticket)")

        EdgeDB.rollback(tx_conn)
      end)

      assert 0 == EdgeDB.query_required_single!(conn, "select count(Ticket)")
    end

    test "not rollbacked changes applied after exiting from main transaction",
         %{conn: conn} do
      EdgeDB.transaction(conn, fn tx_conn ->
        assert {:ok, :ok} =
                 EdgeDB.subtransaction(tx_conn, fn subtx_conn_1 ->
                   {:ok, %EdgeDB.Set{}} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "insert Ticket{ number := 1 }")
                     end)

                   assert 1 == EdgeDB.query_required_single!(subtx_conn_1, "select count(Ticket)")

                   {:error, :rollback} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "insert Ticket{ number := 2 }")
                       EdgeDB.rollback(subtx_conn_2)
                     end)

                   assert 1 == EdgeDB.query_required_single!(subtx_conn_1, "select count(Ticket)")

                   {:ok, %EdgeDB.Set{}} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "insert Ticket{ number := 3 }")
                     end)

                   assert 2 == EdgeDB.query_required_single!(subtx_conn_1, "select count(Ticket)")

                   :ok
                 end)

        assert 2 == EdgeDB.query_required_single!(tx_conn, "select count(Ticket)")

        :ok
      end)

      assert 2 == EdgeDB.query_required_single!(conn, "select count(Ticket)")

      EdgeDB.query!(conn, "delete Ticket")
    end

    test "can be continued after rollback", %{conn: conn} do
      EdgeDB.transaction(conn, fn tx_conn ->
        assert {:ok, "ok"} =
                 EdgeDB.subtransaction(tx_conn, fn subtx_conn ->
                   EdgeDB.query!(subtx_conn, "insert Ticket{ number := 1 }")

                   assert %EdgeDB.Object{} =
                            EdgeDB.query_required_single!(subtx_conn, "select Ticket limit 1")

                   EdgeDB.rollback(subtx_conn, continue: true)

                   assert "ok" = EdgeDB.query_required_single!(subtx_conn, ~s(select "ok"))
                 end)

        assert 0 == EdgeDB.query_required_single!(tx_conn, "select count(Ticket)")
      end)
    end

    test "forbids applying borrowed connections", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/borrowed for subtransaction/, fn ->
        EdgeDB.transaction(conn, fn tx_conn ->
          EdgeDB.subtransaction(tx_conn, fn _subtx_conn ->
            EdgeDB.query!(tx_conn, "select 1")
          end)
        end)
      end

      assert_raise EdgeDB.Error, ~r/borrowed for subtransaction/, fn ->
        EdgeDB.transaction(conn, fn tx_conn ->
          EdgeDB.subtransaction(tx_conn, fn subtx_conn_1 ->
            EdgeDB.subtransaction(subtx_conn_1, fn _subtx_conn_2 ->
              EdgeDB.query!(subtx_conn_1, "select 1")
            end)
          end)
        end)
      end
    end
  end

  describe "EdgeDB.subtransaction!/2" do
    test "unwraps succesful result", %{conn: conn} do
      assert {:ok, 42} =
               EdgeDB.transaction(conn, fn tx_conn ->
                 EdgeDB.subtransaction!(tx_conn, fn subtx_conn1 ->
                   EdgeDB.subtransaction!(subtx_conn1, fn subtx_conn2 ->
                     EdgeDB.query_required_single!(subtx_conn2, "select 42")
                   end)
                 end)
               end)
    end

    test "rollbacks to outer block if error occured", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/violates exclusivity constraint/, fn ->
        EdgeDB.transaction(conn, fn tx_conn ->
          EdgeDB.subtransaction!(tx_conn, fn subtx_conn1 ->
            EdgeDB.subtransaction!(subtx_conn1, fn subtx_conn2 ->
              EdgeDB.query_required_single!(subtx_conn2, "insert Ticket{ number := 1}")
              EdgeDB.query_required_single!(subtx_conn2, "insert Ticket{ number := 1}")
            end)
          end)
        end)
      end

      assert EdgeDB.Set.empty?(EdgeDB.query!(conn, "select Ticket"))
    end

    test "rollbacks to outer block if EdgeDB.rollback/2 called", %{conn: conn} do
      assert {:error, :rollback} =
               EdgeDB.transaction(conn, fn tx_conn ->
                 EdgeDB.subtransaction!(tx_conn, fn subtx_conn1 ->
                   EdgeDB.subtransaction!(subtx_conn1, fn subtx_conn2 ->
                     EdgeDB.query_required_single(subtx_conn2, "insert Ticket{ number := 1}")
                     EdgeDB.rollback(subtx_conn2)
                   end)
                 end)
               end)

      assert EdgeDB.Set.empty?(EdgeDB.query!(conn, "select Ticket"))
    end
  end

  describe "EdgeDB.rollback/2" do
    test "rollbacks transaction", %{conn: conn} do
      {:error, :rollback} =
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query!(conn, "insert User { image := '', name := 'username' }")
          EdgeDB.rollback(conn, reason: :rollback)
        end)
    end
  end

  describe "EdgeDB.as_readonly/2" do
    setup %{conn: conn} do
      %{conn: EdgeDB.as_readonly(conn)}
    end

    test "configures connection that will fail for non-readonly requests", %{conn: conn} do
      exc =
        assert_raise EdgeDB.Error, fn ->
          EdgeDB.query!(conn, "insert Ticket")
        end

      assert exc.type == EdgeDB.DisabledCapabilityError
    end

    test "configures connection that will fail for non-readonly requests in transaction", %{
      conn: conn
    } do
      exc =
        assert_raise EdgeDB.Error, fn ->
          EdgeDB.transaction(conn, fn conn ->
            EdgeDB.query!(conn, "insert Ticket")
          end)
        end

      assert exc.type == EdgeDB.DisabledCapabilityError
    end

    test "configures connection that executes readonly requests", %{conn: conn} do
      assert 1 == EdgeDB.query_single!(conn, "select 1")
    end

    test "configures connection that executes readonly requests in transaction", %{
      conn: conn
    } do
      assert {:ok, 1} ==
               EdgeDB.transaction(conn, fn conn ->
                 EdgeDB.query_single!(conn, "select 1")
               end)
    end
  end

  describe "EdgeDB.with_transaction_options/2" do
    test "accepts options for changing transaction", %{conn: conn} do
      exc =
        assert_raise EdgeDB.Error, ~r/read-only transaction/, fn ->
          conn
          |> EdgeDB.with_transaction_options(readonly: true)
          |> EdgeDB.transaction(fn conn ->
            EdgeDB.query!(conn, "insert Ticket{ number := 1 }")
          end)
        end

      assert exc.type == EdgeDB.TransactionError
    end
  end

  describe "EdgeDB.with_retry_options/2" do
    test "accepts options for changing retries in transactions for transactions conflicts", %{
      conn: conn
    } do
      pid = self()

      exc =
        assert_raise EdgeDB.Error, ~r/test error/, fn ->
          conn
          |> EdgeDB.with_retry_options(
            transaction_conflict: [
              attempts: 10,
              backoff: fn attempt ->
                send(pid, {:attempt, attempt})
                10
              end
            ]
          )
          |> EdgeDB.transaction(fn conn ->
            EdgeDB.query!(conn, "insert Ticket{ number := 1 }")
            raise EdgeDB.TransactionConflictError.new("test error")
          end)
        end

      assert EdgeDB.Set.empty?(EdgeDB.query!(conn, "select Ticket"))

      assert exc.type == EdgeDB.TransactionConflictError

      for attempt <- 1..5 do
        assert_receive {:attempt, ^attempt}
      end
    end

    test "accepts options for changing retries in transactions for network errors", %{
      conn: conn
    } do
      pid = self()

      exc =
        assert_raise EdgeDB.Error, ~r/test error/, fn ->
          conn
          |> EdgeDB.with_retry_options(
            network_error: [
              backoff: fn attempt ->
                send(pid, {:attempt, attempt})
                10
              end
            ]
          )
          |> EdgeDB.transaction(fn conn ->
            EdgeDB.query!(conn, "insert Ticket{ number := 1 }")
            raise EdgeDB.ClientConnectionFailedTemporarilyError.new("test error")
          end)
        end

      assert EdgeDB.Set.empty?(EdgeDB.query!(conn, "select Ticket"))

      assert exc.type == EdgeDB.ClientConnectionFailedTemporarilyError

      for attempt <- 1..3 do
        assert_receive {:attempt, ^attempt}
      end
    end
  end
end
