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
    DynamicSupervisor.start_link(__MODULE__, opts)
  end

  @spec start_connection(Supervisor.supervisor(), Keyword.t()) ::
          DynamicSupervisor.on_start_child()
  def start_connection(supervisor, opts) do
    owner = opts[:owner]
    queue = opts[:queue]
    conn_mod = opts[:conn][:mod]
    conn_opts = opts[:conn][:opts]

    # connections can die quite frequently, so giving them a not unique name may lead to a collision
    DynamicSupervisor.start_child(
      supervisor,
      conn(owner, queue, UUID.uuid4(), conn_mod, conn_opts)
    )
  end

  @spec disconnect_connection(Supervisor.supervisor(), pid()) :: :ok | {:error, :not_found}
  def disconnect_connection(supervisor, connection_pid) do
    DynamicSupervisor.terminate_child(supervisor, connection_pid)
  end

  @impl DynamicSupervisor
  def init(opts \\ []) do
    owner = opts[:owner]
    send(owner, {:set_connections_supervisor, self()})
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp conn(owner, queue, id, conn_mod, opts) do
    child_opts =
      [id: {conn_mod, owner, id}, restart: :temporary] ++ Keyword.take(opts, [:shutdown])

    DBConnection.Connection.child_spec(
      conn_mod,
      [pool_index: id, pool_pid: owner] ++ opts,
      owner,
      queue,
      child_opts
    )
  end
end
