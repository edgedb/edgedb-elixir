defmodule Tests.Support.Connections.PoolConnection do
  use DBConnection

  alias EdgeDB.Connection.InternalRequest

  defmodule State do
    defstruct [
      :pool_pid
    ]
  end

  @spec suggest_pool_concurrency(pid(), pos_integer()) :: :ok
  def suggest_pool_concurrency(pool_pid, concurrency) do
    _result =
      DBConnection.execute!(pool_pid, %InternalRequest{request: :suggest_pool_concurrency}, %{
        concurrency: concurrency
      })

    :ok
  end

  @impl DBConnection
  def connect(opts \\ []) do
    {:ok, %State{pool_pid: opts[:pool_pid]}}
  end

  @impl DBConnection
  def disconnect(_exc, _state) do
    :ok
  end

  @impl DBConnection
  def handle_status(_opts, state) do
    {:idle, state}
  end

  @impl DBConnection
  def ping(state) do
    {:ok, state}
  end

  @impl DBConnection
  def checkout(state) do
    {:ok, state}
  end

  @impl DBConnection
  def handle_prepare(_query, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_prepare/3 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :suggest_pool_concurrency} = query,
        %{concurrency: concurrency},
        _opts,
        state
      ) do
    send(state.pool_pid, {:resize_pool, concurrency})
    {:ok, query, :ok, state}
  end

  @impl DBConnection
  def handle_execute(_query, _params, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_execute/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_close(_query, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_close/3 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_declare(_query, _params, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_declare/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_fetch(_query, _cursor, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_fetch/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_deallocate(_query, _cursor, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_deallocate/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_begin(_opts, state) do
    {:error, state}
  end

  @impl DBConnection
  def handle_commit(_opts, state) do
    {:error, state}
  end

  @impl DBConnection
  def handle_rollback(_opts, state) do
    {:error, state}
  end
end
