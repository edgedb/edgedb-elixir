defmodule Tests.EdgeDB.Pool.EdgeDBPoolTest do
  use Tests.Support.EdgeDBCase

  alias Tests.Support.Connections.PoolConnection

  @max_receive_time :timer.seconds(5)

  describe "EdgeDB.Pool at the beginning" do
    setup do
      {:ok, client} =
        start_supervised(
          {EdgeDB,
           connection: PoolConnection,
           idle_interval: 50,
           show_sensitive_data_on_connection_error: true}
        )

      %{client: client}
    end

    test "doesn't open any connections after start", %{client: client} do
      assert EdgeDB.Pool.concurrency(client) == 0
    end

    test "opens new connection after first request", %{client: client} do
      :executed = EdgeDB.query_required_single!(client, "select 1")
      assert EdgeDB.Pool.concurrency(client) == 1
    end
  end

  describe "EdgeDB.Pool on suggest" do
    setup do
      {:ok, client} =
        start_supervised(
          {EdgeDB,
           connection: PoolConnection,
           idle_interval: 50,
           show_sensitive_data_on_connection_error: true}
        )

      :executed = EdgeDB.query_required_single!(client, "select 1")

      %{client: client}
    end

    test "doesn't open new connections right after suggest from EdgeDB", %{client: client} do
      PoolConnection.suggest_pool_concurrency(client, 100)
      Process.sleep(50)

      assert EdgeDB.Pool.concurrency(client) == 1
    end

    test "opens new connections if required and suggest is greater then current concurrency", %{
      client: client
    } do
      PoolConnection.suggest_pool_concurrency(client, 100)
      Process.sleep(50)

      run_concurrent_queries(client, 3)

      assert EdgeDB.Pool.concurrency(client) == 3
    end

    test "doesn't open new connections if there are idle available", %{
      client: client
    } do
      PoolConnection.suggest_pool_concurrency(client, 100)
      Process.sleep(100)

      run_concurrent_queries(client, 3)

      for _i <- 1..5 do
        EdgeDB.query_required_single!(client, "select 1")
      end

      assert EdgeDB.Pool.concurrency(client) == 3
    end

    test "terminates connections if current pool concurrency greater than suggested", %{
      client: client
    } do
      PoolConnection.suggest_pool_concurrency(client, 100)
      Process.sleep(100)

      run_concurrent_queries(client, 2)

      PoolConnection.suggest_pool_concurrency(client, 1)
      Process.sleep(200)

      assert EdgeDB.Pool.concurrency(client) == 1
    end

    test "terminates connections if current pool concurrency greater than max", %{
      client: client
    } do
      PoolConnection.suggest_pool_concurrency(client, 100)

      run_concurrent_queries(client, 3)

      assert EdgeDB.Pool.concurrency(client) == 3

      EdgeDB.Pool.set_max_concurrency(client, 2)
      Process.sleep(100)

      assert EdgeDB.Pool.concurrency(client) == 2
    end
  end

  describe "EdgeDB.Pool with :max_concurrency option" do
    setup do
      {:ok, client} =
        start_supervised(
          {EdgeDB,
           connection: PoolConnection,
           max_concurrency: 4,
           idle_interval: 50,
           show_sensitive_data_on_connection_error: true}
        )

      %{client: client}
    end

    test "opens no more connections then specified with :max_concurrency option", %{
      client: client
    } do
      PoolConnection.suggest_pool_concurrency(client, 100)
      run_concurrent_queries(client, 5)
      assert EdgeDB.Pool.concurrency(client) == 4
    end

    test "terminates connections if suggested pool concurrency less than previous suggested and max",
         %{
           client: client
         } do
      run_concurrent_queries(client, 5)
      assert EdgeDB.Pool.concurrency(client) == 4

      PoolConnection.suggest_pool_concurrency(client, 3)
      Process.sleep(100)
      assert EdgeDB.Pool.concurrency(client) == 3

      PoolConnection.suggest_pool_concurrency(client, 2)
      Process.sleep(100)
      assert EdgeDB.Pool.concurrency(client) == 2

      PoolConnection.suggest_pool_concurrency(client, 1)
      Process.sleep(100)
      assert EdgeDB.Pool.concurrency(client) == 1
    end
  end

  defp run_concurrent_queries(client, count, max_time \\ 200, sleep_step \\ 50) do
    test_pid = self()

    for i <- 1..count do
      spawn(fn ->
        EdgeDB.transaction(client, fn client ->
          send(test_pid, {:started, i})
          Process.sleep(max_time - sleep_step * (i - 1))
          EdgeDB.query_required_single!(client, "select 1")
        end)

        send(test_pid, {:done, i})
      end)
    end

    for i <- 1..count do
      assert_receive {:started, ^i}, @max_receive_time
      assert_receive {:done, ^i}, @max_receive_time
    end
  end
end
