defmodule EdgeDB.Pool.ConnectionSupervisor do
  @moduledoc false

  use DynamicSupervisor, restart: :temporary

  @spec start_supervised(Keyword.t()) :: DynamicSupervisor.on_start_child()
  def start_supervised(opts \\ []) do
    DBConnection.Watcher.watch(
      DBConnection.ConnectionPool.Supervisor,
      {__MODULE__, opts}
    )
  end

  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    with {:ok, pid} <- DynamicSupervisor.start_link(__MODULE__, opts) do
      # always start with a single child at start
      start_connection(pid, opts)
      {:ok, pid}
    end
  end

  @spec start_connection(Supervisor.supervisor(), Keyword.t()) ::
          DynamicSupervisor.on_start_child()
  def start_connection(supervisor, opts) do
    owner = opts[:owner]
    queue = opts[:queue]
    conn_mod = opts[:conn][:mod]
    conn_opts = opts[:conn][:opts]

    %{active: current_count} = DynamicSupervisor.count_children(supervisor)

    DynamicSupervisor.start_child(
      supervisor,
      conn(owner, queue, current_count + 1, conn_mod, conn_opts)
    )
  end

  @spec disconnect_connection(Supervisor.supervisor(), pid()) :: :ok | {:error, :not_found}
  def disconnect_connection(supervisor, connection_pid) do
    DynamicSupervisor.terminate_child(supervisor, connection_pid)
  end

  @impl DynamicSupervisor
  def init(opts \\ []) do
    owner = opts[:owner]
    conn_opts = opts[:conn][:opts]

    send(owner, {:set_connections_supervisor, self()})

    sup_opts = [strategy: :one_for_one] ++ Keyword.take(conn_opts, [:max_restarts, :max_seconds])
    DynamicSupervisor.init(sup_opts)
  end

  defp conn(owner, queue, id, conn_mod, opts) do
    child_opts = [id: {conn_mod, owner, id}] ++ Keyword.take(opts, [:shutdown])

    DBConnection.Connection.child_spec(
      conn_mod,
      [pool_index: id, pool_pid: owner] ++ opts,
      owner,
      queue,
      child_opts
    )
  end
end
