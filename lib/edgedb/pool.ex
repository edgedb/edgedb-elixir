defmodule EdgeDB.Pool do
  @moduledoc """
  A wrapper around `DBConnection.ConnectionPool` to support dynamic resizing of the connection pool.

  > #### WARNING {: .warning}
  >
  > Consider this module as experimental. You can try to use it in your applications,
  >   but some errors may occur.

  How to use:

  Edit your `config/config.exs` file by adding the following setting to the `:edgedb` configuration:

  ```elixir
  config :edgedb,
    pool: EdgeDB.Pool
  ```

  After that `EdgeDB` driver will start a custom pool that will support dynamic resizing via
    `suggested_pool_concurrency` from the
    [`ParameterStatus`](https://www.edgedb.com/docs/reference/protocol/messages#parameterstatus) message from EdgeDB.
  """

  use GenServer

  alias DBConnection.Holder

  alias EdgeDB.Pool.{
    Codel,
    ConnectionSupervisor,
    State
  }

  @type t() :: GenServer.server()

  @queue_target 50
  @queue_interval 1000
  @idle_interval 1000
  @time_unit 1000

  @doc false
  @spec start_link({module(), Keyword.t()}) :: GenServer.on_start()
  def start_link({conn_mod, opts}) do
    GenServer.start_link(__MODULE__, {conn_mod, opts}, start_opts(opts))
  end

  @doc false
  @spec checkout(t(), list(pid()), Keyword.t()) ::
          {:ok, any(), module(), any(), any()}
          | {:error, Exception.t()}
  def checkout(pool, callers, opts) do
    Holder.checkout(pool, callers, opts)
  end

  @doc false
  @spec disconnect_all(t(), integer(), Keyword.t()) :: :ok
  def disconnect_all(pool, interval, _opts) do
    GenServer.call(pool, {:disconnect_all, interval}, :infinity)
  end

  @doc false
  @spec size(t()) :: integer()
  def size(pool) do
    GenServer.call(pool, :get_current_size)
  end

  @doc false
  @spec set_max_size(t(), integer()) :: integer()
  def set_max_size(pool, max_size) do
    GenServer.call(pool, {:set_max_size, max_size})
  end

  @impl GenServer
  def init({conn_mod, opts}) do
    queue = :ets.new(__MODULE__.Queue, [:protected, :ordered_set])
    ts = {System.monotonic_time(), 0}
    now_in_native = System.monotonic_time()
    now_in_ms = System.convert_time_unit(now_in_native, :native, @time_unit)

    conn_opts = [owner: self(), queue: queue, conn: [mod: conn_mod, opts: opts]]
    {:ok, _pid} = ConnectionSupervisor.start_supervised(conn_opts)

    codel = %Codel{
      target: Keyword.get(opts, :queue_target, @queue_target),
      interval: Keyword.get(opts, :queue_interval, @queue_interval),
      delay: 0,
      slow: false,
      next: now_in_ms,
      poll: nil,
      idle_interval: Keyword.get(opts, :idle_interval, @idle_interval),
      idle: nil
    }

    codel = start_idle(now_in_native, start_poll(now_in_ms, now_in_ms, codel))

    state = %State{
      type: :busy,
      queue: queue,
      codel: codel,
      ts: ts,
      current_size: 1,
      conn_mod: conn_mod,
      conn_opts: conn_opts
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_current_size, _from, %State{} = state) do
    {:reply, state.current_size, state}
  end

  @impl GenServer
  def handle_call({:set_max_size, max_size}, _from, %State{} = state) do
    {:reply, :ok, %State{state | max_size: max_size}}
  end

  @impl GenServer
  def handle_call(request, from, %State{} = state) do
    formatted_state = State.to_connection_pool_format(state)

    {:reply, result, conn_pool_state} =
      DBConnection.ConnectionPool.handle_call(request, from, formatted_state)

    {:reply, result, State.from_connection_pool_format(state, conn_pool_state)}
  end

  @impl GenServer
  def handle_info({:set_connections_supervisor, sup_pid}, state) do
    {:noreply, %State{state | conn_sup: sup_pid}}
  end

  @impl GenServer
  def handle_info({:resize_pool, suggested_pool_concurrency}, state) do
    state = maybe_resize_pool(state, suggested_pool_concurrency)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:"ETS-TRANSFER", holder, _pid, {:checkin, _queue, _extra}} = request,
        %State{} = state
      ) do
    owner = self()

    case :ets.info(holder, :owner) do
      ^owner ->
        maybe_disconnect(request, state)

      :undefined ->
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(request, %State{} = state) do
    formatted_state = State.to_connection_pool_format(state)

    {:noreply, conn_pool_state} =
      DBConnection.ConnectionPool.handle_info(request, formatted_state)

    {:noreply, State.from_connection_pool_format(state, conn_pool_state)}
  end

  defp start_opts(opts) do
    Keyword.take(opts, [:name, :spawn_opt])
  end

  defp start_poll(now, last_sent, %Codel{interval: interval} = codel) do
    timeout = now + interval
    poll = :erlang.start_timer(timeout, self(), {timeout, last_sent}, abs: true)
    %Codel{codel | poll: poll}
  end

  defp start_idle(now_in_native, %Codel{idle_interval: interval} = codel) do
    timeout = System.convert_time_unit(now_in_native, :native, :millisecond) + interval
    idle = :erlang.start_timer(timeout, self(), now_in_native, abs: true)
    %Codel{codel | idle: idle}
  end

  defp maybe_resize_pool(
         %State{current_size: current_size, max_size: max_size} = state,
         suggested_size
       )
       when current_size < suggested_size and suggested_size <= max_size do
    connections_to_add = suggested_size - current_size

    for _id <- 1..connections_to_add do
      ConnectionSupervisor.start_connection(state.conn_sup, state.conn_opts)
    end

    %State{state | current_size: suggested_size, suggested_size: suggested_size}
  end

  defp maybe_resize_pool(
         %State{current_size: current_size, suggested_size: suggested_size} = state,
         new_suggested_size
       )
       when current_size > new_suggested_size and suggested_size != new_suggested_size do
    %State{state | suggested_size: new_suggested_size}
  end

  defp maybe_resize_pool(%State{} = state, _suggested_size) do
    state
  end

  defp maybe_disconnect(
         {:"ETS-TRANSFER", holder, _pid, {:checkin, _queue, _extra}} = request,
         %State{} = state
       ) do
    if disconnect?(state) do
      conn_pid = connection_pid(holder)
      message = "disconnect connection via dynamic resizing"
      err = DBConnection.ConnectionError.exception(message: message, severity: :debug)
      Holder.handle_disconnect(holder, err)
      ConnectionSupervisor.disconnect_connection(state.conn_sup, conn_pid)
      {:noreply, %State{state | current_size: state.current_size - 1}}
    else
      formatted_state = State.to_connection_pool_format(state)

      {:noreply, conn_pool_state} =
        DBConnection.ConnectionPool.handle_info(request, formatted_state)

      state = State.from_connection_pool_format(state, conn_pool_state)
      {:noreply, state}
    end
  end

  defp disconnect?(%State{
         current_size: current_size,
         max_size: max_size
       })
       when current_size > max_size do
    true
  end

  defp disconnect?(%State{
         current_size: current_size,
         suggested_size: suggested_size
       })
       when current_size > suggested_size do
    true
  end

  defp disconnect?(_state) do
    false
  end

  defp connection_pid(holder) do
    [conn] = :ets.lookup(holder, :conn)
    elem(conn, 1)
  end
end
