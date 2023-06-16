defmodule EdgeDB.Pool do
  @moduledoc false

  use GenServer

  alias DBConnection.Holder

  alias EdgeDB.Pool.{
    Codel,
    ConnectionSupervisor,
    State
  }

  @typedoc false
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
  @spec concurrency(t()) :: integer()
  def concurrency(pool) do
    GenServer.call(pool, :get_current_concurrency)
  end

  @doc false
  @spec set_max_concurrency(t(), integer()) :: integer()
  def set_max_concurrency(pool, max_concurrency) do
    GenServer.call(pool, {:set_max_concurrency, max_concurrency})
  end

  @impl GenServer
  def init({conn_mod, opts}) do
    queue = :ets.new(__MODULE__.Queue, [:protected, :ordered_set])
    ts = {System.monotonic_time(), 0}
    now_in_native = System.monotonic_time()
    now_in_ms = System.convert_time_unit(now_in_native, :native, @time_unit)

    conn_opts = [owner: self(), queue: queue, conn: [mod: conn_mod, opts: opts]]
    {:ok, _pid} = ConnectionSupervisor.start_supervised(conn_opts)

    # if we're using sandbox connection then we shouldn't use many connections
    # since in EdgeDB there are only serializable transactions and concurrent requests
    # will break sandbox logic.
    max_concurrency =
      if conn_mod == EdgeDB.Sandbox do
        1
      else
        opts[:max_concurrency]
      end

    idle_limit = opts[:idle_limit]

    codel = %Codel{
      target: Keyword.get(opts, :queue_target, @queue_target),
      interval: Keyword.get(opts, :queue_interval, @queue_interval),
      delay: 0,
      slow: false,
      next: now_in_ms,
      poll: nil,
      idle_interval: Keyword.get(opts, :idle_interval, @idle_interval),
      idle_limit: idle_limit || (max_concurrency || 0),
      idle: nil
    }

    codel = start_idle(now_in_native, start_poll(now_in_ms, now_in_ms, codel))

    state = %State{
      type: :busy,
      queue: queue,
      codel: codel,
      ts: ts,
      current_concurrency: 0,
      max_concurrency: max_concurrency,
      conn_mod: conn_mod,
      conn_opts: conn_opts,
      pool_idle_limit: idle_limit
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_current_concurrency, _from, %State{} = state) do
    {:reply, state.current_concurrency, state}
  end

  @impl GenServer
  def handle_call({:set_max_concurrency, max_concurrency}, _from, %State{} = state) do
    {:reply, :ok, %State{state | max_concurrency: max_concurrency}}
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
  def handle_info({:concurrency_suggest, suggested_pool_concurrency}, state) do
    {:noreply, %State{state | suggested_concurrency: suggested_pool_concurrency}}
  end

  @impl GenServer
  def handle_info(
        {:disconnected, _conn_pid, %DBConnection.ConnectionError{reason: :exceed_limit}},
        %State{} = state
      ) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:disconnected, _conn_pid, exc}, %State{} = state) do
    state =
      with %EdgeDB.Error{tags: tags} <- exc,
           true <- :should_reconnect in tags do
        ConnectionSupervisor.start_connection(state.conn_sup, state.conn_opts)
        state
      else
        _other ->
          %State{state | current_concurrency: state.current_concurrency - 1}
      end

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
  def handle_info(
        {:db_connection, _from, {:checkout, _caller, _now, _queue?}} = request,
        %State{} = state
      ) do
    state = maybe_create_new_connection(state)
    formatted_state = State.to_connection_pool_format(state)

    {:noreply, conn_pool_state} =
      DBConnection.ConnectionPool.handle_info(request, formatted_state)

    {:noreply, State.from_connection_pool_format(state, conn_pool_state)}
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

  defp maybe_create_new_connection(%State{} = state) do
    max_allowed_connections = min(state.max_concurrency, state.suggested_concurrency) || 1

    if (state.type == :busy or :ets.info(state.queue, :size) == 0) and
         state.current_concurrency < max_allowed_connections do
      ConnectionSupervisor.start_connection(state.conn_sup, state.conn_opts)

      concurrency = state.current_concurrency + 1

      %State{
        state
        | current_concurrency: concurrency,
          codel: maybe_set_codel_idle_limit(state, concurrency)
      }
    else
      state
    end
  end

  defp maybe_disconnect(
         {:"ETS-TRANSFER", holder, _pid, {:checkin, _queue, _extra}} = request,
         %State{} = state
       ) do
    if disconnect?(state) do
      conn_pid = connection_pid(holder)
      message = "disconnect connection via dynamic resizing"

      err =
        DBConnection.ConnectionError.exception(
          message: message,
          severity: :debug,
          reason: :exceed_limit
        )

      Holder.handle_disconnect(holder, err)
      ConnectionSupervisor.disconnect_connection(state.conn_sup, conn_pid)

      concurrency = state.current_concurrency - 1

      {:noreply,
       %State{
         state
         | current_concurrency: concurrency,
           codel: maybe_set_codel_idle_limit(state, concurrency)
       }}
    else
      formatted_state = State.to_connection_pool_format(state)

      {:noreply, conn_pool_state} =
        DBConnection.ConnectionPool.handle_info(request, formatted_state)

      state = State.from_connection_pool_format(state, conn_pool_state)
      {:noreply, state}
    end
  end

  defp disconnect?(%State{
         current_concurrency: current_concurrency,
         max_concurrency: max_concurrency
       })
       when current_concurrency > max_concurrency do
    true
  end

  defp disconnect?(%State{
         current_concurrency: current_concurrency,
         suggested_concurrency: suggested_concurrency
       })
       when current_concurrency > suggested_concurrency do
    true
  end

  defp disconnect?(_state) do
    false
  end

  defp connection_pid(holder) do
    [conn] = :ets.lookup(holder, :conn)
    elem(conn, 1)
  end

  defp maybe_set_codel_idle_limit(%State{pool_idle_limit: nil, codel: codel}, concurrency) do
    %Codel{codel | idle_limit: concurrency}
  end

  defp maybe_set_codel_idle_limit(%State{codel: codel}, _concurrency) do
    codel
  end
end
