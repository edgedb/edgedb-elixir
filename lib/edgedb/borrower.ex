defmodule EdgeDB.Borrower do
  use GenServer

  alias EdgeDB.Protocol.Error

  @reasons_to_borrow ~w(
    transaction
    subtransaction
  )a

  defmodule State do
    defstruct borrowed: %{}

    @type t() :: %__MODULE__{
            borrowed: %{DBConnection.conn() => :transaction | :subtransaction}
          }
  end

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec borrow!(DBConnection.conn(), term(), (() -> any())) :: any() | no_return()
  def borrow!(conn, reason, callback) when reason in @reasons_to_borrow do
    case borrow(conn, reason) do
      :ok ->
        execute_on_borrowed(conn, callback)

      {:error, exc} ->
        raise exc
    end
  end

  @spec ensure_unborrowed!(DBConnection.conn()) :: :ok | no_return()
  def ensure_unborrowed!(conn) do
    case GenServer.call(__MODULE__, {:check_borrowed, conn}) do
      :ok ->
        :ok

      {:error, exc} ->
        raise exc
    end
  end

  @impl GenServer
  def init(_opts \\ []) do
    {:ok, %State{}}
  end

  @impl GenServer
  def handle_call({:borrow, conn, reason}, _from, %State{borrowed: borrowed} = state) do
    case borrowed[conn] do
      nil ->
        {:reply, :ok,
         %State{
           state
           | borrowed: Map.put(borrowed, conn, reason)
         }}

      :transaction ->
        {:reply,
         {
           :error,
           Error.interface_error("connection is already borrowed for transaction")
         }, state}

      :subtransaction ->
        {:reply,
         {
           :error,
           Error.interface_error("connection is already borrowed for subtransaction")
         }, state}
    end
  end

  @impl GenServer
  def handle_call({:check_borrowed, conn}, _from, %State{borrowed: borrowed} = state) do
    case borrowed[conn] do
      nil ->
        {:reply, :ok, state}

      :transaction ->
        {:reply,
         {
           :error,
           Error.interface_error("connection is already borrowed for transaction")
         }, state}

      :subtransaction ->
        {:reply,
         {
           :error,
           Error.interface_error("connection is already borrowed for subtransaction")
         }, state}
    end
  end

  @impl GenServer
  def handle_cast({:unborrow, conn}, %State{borrowed: borrowed} = state) do
    {:noreply, %State{state | borrowed: Map.delete(borrowed, conn)}}
  end

  defp borrow(conn, reason) do
    GenServer.call(__MODULE__, {:borrow, conn, reason})
  end

  defp unborrow(conn) do
    GenServer.cast(__MODULE__, {:unborrow, conn})
  end

  defp execute_on_borrowed(conn, callback) do
    callback.()
  rescue
    exc ->
      unborrow(conn)
      reraise exc, __STACKTRACE__
  else
    result ->
      unborrow(conn)
      result
  end
end
