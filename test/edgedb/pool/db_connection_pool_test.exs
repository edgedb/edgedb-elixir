defmodule Tests.EdgeDB.Pool.DBConnectionPoolTest do
  use Tests.Support.EdgeDBCase

  @max_receive_time :timer.seconds(5)

  describe "DBConnection.ConnectionPool" do
    setup do
      {:ok, client} =
        start_supervised(
          {EdgeDB,
           pool: DBConnection.ConnectionPool,
           idle_interval: 50,
           pool_size: 10,
           show_sensitive_data_on_connection_error: true}
        )

      %{client: client}
    end

    test "runs concurrent queries through pool", %{client: client} do
      run_concurrent_queries(client, 3)
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
