defmodule EdgeDB.Pool do
  @moduledoc """
  A wrapper around `DBConnection.ConnectionPool` to support dynamic resizing of the connection pool.
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

    # if we're using sanbox  connection then we shouldn't use many connections
    # since in EdgeDB there are only serializable transactions and concurrent requests
    # will break sandbox logic
    # similar if we're using subtransaction, then we should ensure it will have a single connection
    max_concurrency =
      if conn_mod == EdgeDB.Sandbox or conn_mod == EdgeDB.Subtransaction do
        1
      else
        opts[:max_concurrency]
      end

    state = %State{
      type: :busy,
      queue: queue,
      codel: codel,
      ts: ts,
      current_concurrency: 1,
      max_concurrency: max_concurrency,
      conn_mod: conn_mod,
      conn_opts: conn_opts
    }

    client = %EdgeDB.Client{
      conn: self(),
      transaction_options: opts[:transaction] || [],
      retry_options: opts[:retry] || [],
      state: opts[:state] || %EdgeDB.State{}
    }

    Registry.register(EdgeDB.ClientsRegistry, self(), client)

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_current_concurrency, _from, %State{} = state) do
    {:reply, state.current_concurrency, state}
  end

  @impl GenServer
  def handle_call({:set_max_concurrency, max_concurrency}, _from, %State{} = state) do
    state = maybe_resize_pool(%State{state | max_concurrency: max_concurrency}, nil)
    {:reply, :ok, state}
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
         %State{
           current_concurrency: current_concurrency,
           max_concurrency: max_concurrency
         } = state,
         suggested_concurrency
       )
       when current_concurrency < suggested_concurrency and
              suggested_concurrency <= max_concurrency do
    connections_to_add = suggested_concurrency - current_concurrency

    for _id <- 1..connections_to_add do
      ConnectionSupervisor.start_connection(state.conn_sup, state.conn_opts)
    end

    %State{
      state
      | current_concurrency: suggested_concurrency,
        suggested_concurrency: suggested_concurrency
    }
  end

  defp maybe_resize_pool(
         %State{
           current_concurrency: current_concurrency,
           max_concurrency: max_concurrency
         } = state,
         suggested_concurrency
       )
       when current_concurrency < max_concurrency and is_integer(max_concurrency) do
    connections_to_add = max_concurrency - current_concurrency

    for _id <- 1..connections_to_add do
      ConnectionSupervisor.start_connection(state.conn_sup, state.conn_opts)
    end

    %State{
      state
      | current_concurrency: max_concurrency,
        suggested_concurrency: suggested_concurrency
    }
  end

  defp maybe_resize_pool(%State{} = state, suggested_concurrency) do
    %State{state | suggested_concurrency: suggested_concurrency}
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
      {:noreply, %State{state | current_concurrency: state.current_concurrency - 1}}
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
end
