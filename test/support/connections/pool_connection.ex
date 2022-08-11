defmodule Tests.Support.Connections.PoolConnection do
  use DBConnection

  alias EdgeDB.Connection.InternalRequest
  alias EdgeDB.Protocol.CodecStorage

  defmodule State do
    defstruct [
      :pool_pid,
      transaction_state: :not_in_transaction
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
    {status(state), state}
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
  def handle_prepare(query, _opts, state) do
    {:ok,
     %EdgeDB.Query{
       query
       | input_codec: CodecStorage.null_codec_id(),
         output_codec: CodecStorage.null_codec_id(),
         codec_storage: CodecStorage.new()
     }, state}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :suggest_pool_concurrency} = query,
        %{concurrency: concurrency},
        _opts,
        state
      ) do
    send(state.pool_pid, {:concurrency_suggest, concurrency})
    {:ok, query, :ok, state}
  end

  @impl DBConnection
  def handle_execute(query, _params, _opts, state) do
    {:ok, query, %EdgeDB.Result{cardinality: :no_result, set: %EdgeDB.Set{}}, state}
  end

  @impl DBConnection
  def handle_close(_query, _opts, state) do
    {:ok, :ok, state}
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
    {:ok, result(), %State{state | transaction_state: :in_transaction}}
  end

  @impl DBConnection
  def handle_commit(_opts, state) do
    {:ok, result(), %State{state | transaction_state: :not_in_transaction}}
  end

  @impl DBConnection
  def handle_rollback(_opts, state) do
    {:ok, result(), %State{state | transaction_state: :not_in_transaction}}
  end

  defp status(%State{transaction_state: :not_in_transaction}) do
    :idle
  end

  defp status(%State{transaction_state: :in_transaction}) do
    :transaction
  end

  defp status(%State{transaction_state: :in_failed_transaction}) do
    :error
  end

  defp result do
    %EdgeDB.Result{cardinality: :no_result, set: %EdgeDB.Set{}}
  end
end
