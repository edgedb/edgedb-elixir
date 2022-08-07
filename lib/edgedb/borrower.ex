defmodule EdgeDB.Borrower do
  @moduledoc false

  use GenServer

  @reasons_to_borrow ~w(
    transaction
    subtransaction
  )a

  defmodule State do
    @moduledoc false

    defstruct borrowed: %{}

    @type t() :: %__MODULE__{
            borrowed: %{EdgeDB.client() => :transaction | :subtransaction}
          }
  end

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec borrow!(EdgeDB.client(), term(), (() -> any())) :: any() | no_return()
  def borrow!(client, reason, callback) when reason in @reasons_to_borrow do
    case borrow(client, reason) do
      :ok ->
        execute_on_borrowed(client, callback)

      {:error, {:borrowed, reason}} ->
        raise error_for_reason(reason)
    end
  end

  @spec ensure_unborrowed!(EdgeDB.client()) :: :ok | no_return()
  def ensure_unborrowed!(client) do
    case GenServer.call(__MODULE__, {:check_borrowed, client}) do
      :unborrowed ->
        :ok

      reason ->
        raise error_for_reason(reason)
    end
  end

  @impl GenServer
  def init(_opts \\ []) do
    {:ok, %State{}}
  end

  @impl GenServer
  def handle_call({:borrow, client, reason}, _from, %State{borrowed: borrowed} = state) do
    case borrowed[client] do
      nil ->
        {:reply, :ok, %State{state | borrowed: Map.put(borrowed, client, reason)}}

      reason ->
        {:reply, {:error, {:borrowed, reason}}, state}
    end
  end

  @impl GenServer
  def handle_call({:check_borrowed, client}, _from, %State{borrowed: borrowed} = state) do
    case borrowed[client] do
      nil ->
        {:reply, :unborrowed, state}

      reason ->
        {:reply, reason, state}
    end
  end

  @impl GenServer
  def handle_cast({:unborrow, client}, %State{borrowed: borrowed} = state) do
    {:noreply, %State{state | borrowed: Map.delete(borrowed, client)}}
  end

  defp borrow(client, reason) do
    GenServer.call(__MODULE__, {:borrow, client, reason})
  end

  defp unborrow(client) do
    GenServer.cast(__MODULE__, {:unborrow, client})
  end

  defp error_for_reason(:transaction) do
    EdgeDB.InterfaceError.new("client is already borrowed for transaction")
  end

  defp error_for_reason(:subtransaction) do
    EdgeDB.InterfaceError.new("client is already borrowed for subtransaction")
  end

  defp execute_on_borrowed(client, callback) do
    callback.()
  rescue
    exc ->
      unborrow(client)
      reraise exc, __STACKTRACE__
  else
    result ->
      unborrow(client)
      result
  end
end
