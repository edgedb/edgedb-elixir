defmodule Tests.EdgeDB.PoolTest do
  use Tests.Support.EdgeDBCase

  alias Tests.Support.Connections.PoolConnection

  describe "EdgeDB.Pool" do
    setup do
      {:ok, pool} =
        start_supervised(
          {EdgeDB,
           connection: PoolConnection,
           backoff_type: :stop,
           max_restarts: 0,
           idle_interval: 1,
           show_sensitive_data_on_connection_error: true}
        )

      %{pool: pool}
    end

    test "opens only single connection after start", %{pool: pool} do
      assert EdgeDB.Pool.concurrency(pool) == 1
    end

    test "opens new connections after suggest from EdgeDB", %{pool: pool} do
      PoolConnection.suggest_pool_concurrency(pool, 100)
      Process.sleep(100)

      assert EdgeDB.Pool.concurrency(pool) == 100
    end

    test "terminates connections if current pool concurrency greater than suggested", %{
      pool: pool
    } do
      PoolConnection.suggest_pool_concurrency(pool, 100)
      Process.sleep(100)

      PoolConnection.suggest_pool_concurrency(pool, 25)
      Process.sleep(1000)

      assert EdgeDB.Pool.concurrency(pool) == 25
    end

    test "terminates connections if current pool concurrency greater than max", %{
      pool: pool
    } do
      PoolConnection.suggest_pool_concurrency(pool, 100)
      Process.sleep(100)

      EdgeDB.Pool.set_max_concurrency(pool, 25)
      Process.sleep(1000)

      assert EdgeDB.Pool.concurrency(pool) == 25
    end
  end

  describe "EdgeDB.Pool with :max_concurrency option" do
    setup do
      {:ok, pool} =
        start_supervised(
          {EdgeDB,
           connection: PoolConnection,
           max_concurrency: 50,
           backoff_type: :stop,
           max_restarts: 0,
           idle_interval: 1,
           show_sensitive_data_on_connection_error: true}
        )

      %{pool: pool}
    end

    test "opens no more connections then specified with :max_concurrency option", %{
      pool: pool
    } do
      PoolConnection.suggest_pool_concurrency(pool, 100)
      Process.sleep(1000)

      assert EdgeDB.Pool.concurrency(pool) == 50
    end

    test "terminates connections if suggested pool concurrency less than previous suggested and max",
         %{
           pool: pool
         } do
      PoolConnection.suggest_pool_concurrency(pool, 100)

      Process.sleep(1000)
      assert EdgeDB.Pool.concurrency(pool) == 50

      PoolConnection.suggest_pool_concurrency(pool, 50)

      Process.sleep(1000)
      assert EdgeDB.Pool.concurrency(pool) == 50

      PoolConnection.suggest_pool_concurrency(pool, 25)

      Process.sleep(1000)
      assert EdgeDB.Pool.concurrency(pool) == 25
    end
  end
end
