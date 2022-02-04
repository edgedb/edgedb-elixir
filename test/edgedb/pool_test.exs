defmodule Tests.EdgeDB.PoolTest do
  use Tests.Support.EdgeDBCase

  # TODO: add better tests for resizing via server hints using the protocol mocks

  setup do
    {:ok, pool} =
      start_supervised(
        {EdgeDB,
         pool: EdgeDB.Pool,
         backoff_type: :stop,
         max_restarts: 0,
         idle_interval: 1,
         show_sensitive_data_on_connection_error: true}
      )

    %{pool: pool}
  end

  describe "EdgeDB.Pool" do
    test "opens new connections after suggest from EdgeDB", %{pool: pool} do
      Process.sleep(100)
      # default hint will include 100
      assert EdgeDB.Pool.size(pool) > 10
    end

    test "terminates connections if current pool size greater than required", %{pool: pool} do
      Process.sleep(1000)
      EdgeDB.Pool.set_max_size(pool, 10)
      Process.sleep(1000)
      assert EdgeDB.Pool.size(pool) == 10
    end
  end
end
