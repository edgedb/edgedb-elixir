defmodule Tests.APITest do
  use Tests.Support.EdgeDBCase

  alias EdgeDB.Protocol.Error

  setup :edgedb_connection

  describe "EdgeDB.query/4" do
    test "returns EdgeDB.Set on succesful query", %{conn: conn} do
      assert {:ok, %EdgeDB.Set{}} = EdgeDB.query(conn, "SELECT 1")
    end

    test "returns error on failed query", %{conn: conn} do
      assert {:error, %Error{}} = EdgeDB.query(conn, "SELECT {1, 2, 3}", [], cardinality: :one)
    end
  end

  describe "EdgeDB.query_json/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert {:ok, "[{\"number\" : 1}]"} = EdgeDB.query_json(conn, "SELECT { number := 1 }")
    end
  end

  describe "EdgeDB.query!/4" do
    test "returns EdgeDB.Set on succesful query", %{conn: conn} do
      assert %EdgeDB.Set{} = EdgeDB.query!(conn, "SELECT 1")
    end

    test "raises error on failed query", %{conn: conn} do
      assert_raise Error, fn ->
        EdgeDB.query!(conn, "SELECT {1, 2, 3}", [], cardinality: :one)
      end
    end
  end

  describe "EdgeDB.query_json!/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert "[{\"number\" : 1}]" = EdgeDB.query_json!(conn, "SELECT { number := 1 }")
    end
  end

  describe "EdgeDB.query_single/4" do
    test "returns result on succesful query", %{conn: conn} do
      assert {:ok, 1} = EdgeDB.query_single(conn, "SELECT 1")
    end

    test "raises error on failed query", %{conn: conn} do
      {:error, %Error{}} = EdgeDB.query_single(conn, "SELECT {1, 2, 3}", [], cardinality: :one)
    end
  end

  describe "EdgeDB.query_single!/4" do
    test "returns result on succesful query", %{conn: conn} do
      assert 1 = EdgeDB.query_single!(conn, "SELECT 1")
    end

    test "raises error on failed query", %{conn: conn} do
      assert_raise Error, fn ->
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query_single!(conn, "SELECT {1, 2, 3}", [], cardinality: :one)
        end)
      end
    end
  end

  describe "EdgeDB.query_required_single/4" do
    test "returns result on succesful query", %{conn: conn} do
      assert {:ok, 1} = EdgeDB.query_required_single(conn, "SELECT 1")
    end

    test "raises error on failed query", %{conn: conn} do
      {:error, %Error{}} = EdgeDB.query_required_single(conn, "SELECT <int64>{}", [])
    end
  end

  describe "EdgeDB.query_required_single!/4" do
    test "returns result on succesful query", %{conn: conn} do
      assert 1 = EdgeDB.query_required_single!(conn, "SELECT 1")
    end

    test "raises error on failed query", %{conn: conn} do
      assert_raise Error, fn ->
        EdgeDB.query_required_single!(conn, "SELECT <int64>{}")
      end
    end
  end

  describe "EdgeDB.query_single_json/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert {:ok, "{\"number\" : 1}"} = EdgeDB.query_single_json(conn, "SELECT { number := 1 }")
    end

    test "returns JSON null for empty set", %{conn: conn} do
      assert {:ok, "null"} = EdgeDB.query_single_json(conn, "SELECT <int64>{}")
    end
  end

  describe "EdgeDB.query_single_json!/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert "{\"number\" : 1}" = EdgeDB.query_single_json!(conn, "SELECT { number := 1 }")
    end
  end

  describe "EdgeDB.query_required_single_json/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert {:ok, "1"} = EdgeDB.query_required_single_json(conn, "SELECT 1")
    end
  end

  describe "EdgeDB.query_required_single_json!/4" do
    test "returns decoded JSON on succesful query", %{conn: conn} do
      assert "1" = EdgeDB.query_required_single_json!(conn, "SELECT 1")
    end
  end

  describe "EdgeDB.transaction/3" do
    test "commit result if no error occured", %{conn: conn} do
      {:ok, %EdgeDB.Object{id: user_id}} =
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query_single!(conn, "INSERT User { image := '', name := 'username' }")
        end)

      %EdgeDB.Object{id: ^user_id} =
        EdgeDB.query_single!(conn, "DELETE User FILTER .id = <uuid>$0", [user_id])

      assert EdgeDB.Set.empty?(
               EdgeDB.query!(conn, "SELECT User FILTER .id = <uuid>$0", [user_id])
             )
    end

    test "automaticly rollbacks if error occured", %{conn: conn} do
      assert_raise RuntimeError, fn ->
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query!(conn, "INSERT User { image := '', name := 'username' }")
          raise RuntimeError
        end)
      end

      assert EdgeDB.Set.empty?(EdgeDB.query!(conn, "SELECT User"))
    end

    test "automaticly rollbacks if error in EdgeDB occured", %{conn: conn} do
      assert_raise Error, ~r/violates exclusivity constraint/, fn ->
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query!(conn, "INSERT Ticket { number := 1 }")
          EdgeDB.query!(conn, "INSERT Ticket { number := 1 }")
        end)
      end

      assert EdgeDB.Set.empty?(EdgeDB.query!(conn, "SELECT Ticket"))
    end

    test "nested transactions raises borrow error", %{conn: conn} do
      assert_raise Error, ~r/borrowed for transaction/, fn ->
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.transaction(conn, fn conn ->
            EdgeDB.query!(conn, "SELECT 1")
          end)
        end)
      end
    end

    test "forbids using original connection inside", %{conn: conn} do
      assert_raise Error, ~r/borrowed for transaction/, fn ->
        EdgeDB.transaction(conn, fn _tx_conn ->
          EdgeDB.query!(conn, "SELECT 1")
        end)
      end

      assert "ok" = EdgeDB.query_required_single!(conn, ~s(SELECT "ok"))
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

  describe "EdgeDB.subtransaction/3" do
    test "allowed only on connections in transactions", %{conn: conn} do
      assert_raise Error, ~r/(already in transaction)|(another subtransaction)/, fn ->
        EdgeDB.subtransaction(conn, fn _subtx_conn ->
          :ok
        end)
      end
    end

    test "rollbacks nested transaction without breaking the outer", %{conn: conn} do
      EdgeDB.transaction(conn, fn tx_conn ->
        assert {:error, :subtx_rollback} =
                 EdgeDB.subtransaction(tx_conn, fn subtx_conn ->
                   EdgeDB.query!(subtx_conn, "INSERT Ticket{ number := 1 }")

                   assert %EdgeDB.Object{} =
                            EdgeDB.query_required_single!(subtx_conn, "SELECT Ticket LIMIT 1")

                   EdgeDB.rollback(subtx_conn, reason: :subtx_rollback)
                 end)

        assert 0 == EdgeDB.query_required_single!(tx_conn, "SELECT count(Ticket)")
      end)
    end

    test "not rollbacked changes from inner subtransactions seen to outer and to main transaction",
         %{conn: conn} do
      EdgeDB.transaction(conn, fn tx_conn ->
        assert {:ok, :ok} =
                 EdgeDB.subtransaction(tx_conn, fn subtx_conn_1 ->
                   {:ok, %EdgeDB.Set{}} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "INSERT Ticket{ number := 1 }")
                     end)

                   assert 1 == EdgeDB.query_required_single!(subtx_conn_1, "SELECT count(Ticket)")

                   {:error, :rollback} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "INSERT Ticket{ number := 2 }")
                       EdgeDB.rollback(subtx_conn_2)
                     end)

                   assert 1 == EdgeDB.query_required_single!(subtx_conn_1, "SELECT count(Ticket)")

                   {:ok, %EdgeDB.Set{}} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "INSERT Ticket{ number := 3 }")
                     end)

                   assert 2 == EdgeDB.query_required_single!(subtx_conn_1, "SELECT count(Ticket)")

                   :ok
                 end)

        assert 2 == EdgeDB.query_required_single!(tx_conn, "SELECT count(Ticket)")

        EdgeDB.rollback(tx_conn)
      end)

      assert 0 == EdgeDB.query_required_single!(conn, "SELECT count(Ticket)")
    end

    test "not rollbacked changes applied after exiting from main transaction",
         %{conn: conn} do
      EdgeDB.transaction(conn, fn tx_conn ->
        assert {:ok, :ok} =
                 EdgeDB.subtransaction(tx_conn, fn subtx_conn_1 ->
                   {:ok, %EdgeDB.Set{}} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "INSERT Ticket{ number := 1 }")
                     end)

                   assert 1 == EdgeDB.query_required_single!(subtx_conn_1, "SELECT count(Ticket)")

                   {:error, :rollback} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "INSERT Ticket{ number := 2 }")
                       EdgeDB.rollback(subtx_conn_2)
                     end)

                   assert 1 == EdgeDB.query_required_single!(subtx_conn_1, "SELECT count(Ticket)")

                   {:ok, %EdgeDB.Set{}} =
                     EdgeDB.subtransaction(subtx_conn_1, fn subtx_conn_2 ->
                       EdgeDB.query!(subtx_conn_2, "INSERT Ticket{ number := 3 }")
                     end)

                   assert 2 == EdgeDB.query_required_single!(subtx_conn_1, "SELECT count(Ticket)")

                   :ok
                 end)

        assert 2 == EdgeDB.query_required_single!(tx_conn, "SELECT count(Ticket)")

        :ok
      end)

      assert 2 == EdgeDB.query_required_single!(conn, "SELECT count(Ticket)")

      EdgeDB.query!(conn, "DELETE Ticket")
    end

    test "can be continued after rollback", %{conn: conn} do
      EdgeDB.transaction(conn, fn tx_conn ->
        assert {:ok, "ok"} =
                 EdgeDB.subtransaction(tx_conn, fn subtx_conn ->
                   EdgeDB.query!(subtx_conn, "INSERT Ticket{ number := 1 }")

                   assert %EdgeDB.Object{} =
                            EdgeDB.query_required_single!(subtx_conn, "SELECT Ticket LIMIT 1")

                   EdgeDB.rollback(subtx_conn, continue: true)

                   assert "ok" = EdgeDB.query_required_single!(subtx_conn, ~s(SELECT "ok"))
                 end)

        assert 0 == EdgeDB.query_required_single!(tx_conn, "SELECT count(Ticket)")
      end)
    end

    test "forbids applying borrowed connections", %{conn: conn} do
      assert_raise Error, ~r/borrowed for subtransaction/, fn ->
        EdgeDB.transaction(conn, fn tx_conn ->
          EdgeDB.subtransaction(tx_conn, fn _subtx_conn ->
            EdgeDB.query!(tx_conn, "SELECT 1")
          end)
        end)
      end

      assert_raise Error, ~r/borrowed for subtransaction/, fn ->
        EdgeDB.transaction(conn, fn tx_conn ->
          EdgeDB.subtransaction(tx_conn, fn subtx_conn_1 ->
            EdgeDB.subtransaction(subtx_conn_1, fn _subtx_conn_2 ->
              EdgeDB.query!(subtx_conn_1, "SELECT 1")
            end)
          end)
        end)
      end
    end
  end

  describe "EdgeDB.rollback/2" do
    test "rollbacks transaction", %{conn: conn} do
      {:error, :rollback} =
        EdgeDB.transaction(conn, fn conn ->
          EdgeDB.query!(conn, "INSERT User { image := '', name := 'username' }")
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
        assert_raise Error, fn ->
          EdgeDB.query!(conn, "INSERT Ticket")
        end

      assert exc.name == "DisabledCapabilityError"
    end

    test "configures connection that will fail for non-readonly requests in transaction", %{
      conn: conn
    } do
      exc =
        assert_raise Error, fn ->
          EdgeDB.transaction(conn, fn conn ->
            EdgeDB.query!(conn, "INSERT Ticket")
          end)
        end

      assert exc.name == "DisabledCapabilityError"
    end

    test "configures connection that executes readonly requests", %{conn: conn} do
      assert 1 == EdgeDB.query_single!(conn, "SELECT 1")
    end

    test "configures connection that executes readonly requests in transaction", %{
      conn: conn
    } do
      assert {:ok, 1} ==
               EdgeDB.transaction(conn, fn conn ->
                 EdgeDB.query_single!(conn, "SELECT 1")
               end)
    end
  end

  describe "EdgeDB.with_transaction_options/2" do
    test "accepts options for changing transaction", %{conn: conn} do
      exc =
        assert_raise Error, ~r/read-only transaction/, fn ->
          conn
          |> EdgeDB.with_transaction_options(readonly: true)
          |> EdgeDB.transaction(fn conn ->
            EdgeDB.query!(conn, "INSERT Ticket{ number := 1 }")
          end)
        end

      assert exc.name == "TransactionError"
    end
  end

  describe "EdgeDB.with_retry_options/2" do
    test "accepts options for changing retries in transactions for transactions conflicts", %{
      conn: conn
    } do
      pid = self()

      exc =
        assert_raise Error, ~r/test error/, fn ->
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
            EdgeDB.query!(conn, "INSERT Ticket{ number := 1 }")
            raise Error.transaction_conflict_error("test error")
          end)
        end

      assert EdgeDB.Set.empty?(EdgeDB.query!(conn, "SELECT Ticket"))

      assert exc.name == "TransactionConflictError"

      for attempt <- 1..5 do
        assert_receive {:attempt, ^attempt}
      end
    end

    test "accepts options for changing retries in transactions for network errors", %{
      conn: conn
    } do
      pid = self()

      exc =
        assert_raise Error, ~r/test error/, fn ->
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
            EdgeDB.query!(conn, "INSERT Ticket{ number := 1 }")
            raise Error.client_connection_failed_temporarily_error("test error")
          end)
        end

      assert EdgeDB.Set.empty?(EdgeDB.query!(conn, "SELECT Ticket"))

      assert exc.name == "ClientConnectionFailedTemporarilyError"

      for attempt <- 1..3 do
        assert_receive {:attempt, ^attempt}
      end
    end
  end
end
