defmodule EdgeDB.Sandbox do
  @moduledoc since: "0.2.0"
  @moduledoc """
  Custom connection for tests that involve modifying the database through the driver.

  This connection, when started, wraps the actual connection to EdgeDB into a transaction using
    the `start transaction` statement. And then further calls to `EdgeDB.transaction/3` will result
    in executing `declare savepoint` statement instead of `start transaction`. This connection
    doesn't affect the availability of the `EdgeDB.subtransaction/2` and `EdgeDB.subtransaction!/2` calls,
    you can continue to use them with this module.

  To use this module in tests, change the configuration of the `:edgedb` application in the `config/tests.exs`:

  ```elixir
  config :edgedb,
    connection: EdgeDB.Sandbox
  ```

  Then modify the test case to initialize the sandbox when you run the test and to clean the sandbox
    at the end of the test:

  ```elixir
  defmodule MyApp.TestCase do
    use ExUnit.CaseTemplate

    # other stuff for this case (e.g. Phoenix setup, Plug configuration, etc.)

    setup _context do
      EdgeDB.Sandbox.initialize(MyApp.EdgeDB)

      on_exit(fn ->
        EdgeDB.Sandbox.clean(MyApp.EdgeDB)
      end)

      :ok
    end
  end
  ```
  """

  use DBConnection

  alias EdgeDB.Connection

  alias EdgeDB.Connection.{
    InternalRequest,
    QueryBuilder
  }

  alias EdgeDB.Protocol.Enums

  defmodule State do
    @moduledoc false

    defstruct [
      :internal_state,
      :savepoint,
      conn_state: :not_in_transaction
    ]

    @type t() :: %__MODULE__{
            conn_state: Enums.transaction_state(),
            internal_state: Connection.State.t(),
            savepoint: String.t() | nil
          }
  end

  @doc """
  Wrap a connection in a transaction.
  """
  @spec initialize(GenServer.server()) :: :ok
  def initialize(conn) do
    DBConnection.execute!(conn, %InternalRequest{request: :start_sandbox_transaction}, [], [])
    :ok
  end

  @doc """
  Release the connection transaction.
  """
  @spec clean(GenServer.server()) :: :ok
  def clean(conn) do
    DBConnection.execute!(conn, %InternalRequest{request: :rollback_sandbox_transaction}, [], [])
    :ok
  end

  @impl DBConnection
  def checkout(%State{} = state) do
    {:ok, state}
  end

  @impl DBConnection
  def connect(opts \\ []) do
    with {:ok, internal_state} <- Connection.connect(opts) do
      {:ok, %State{internal_state: internal_state}}
    end
  end

  @impl DBConnection
  def disconnect(exc, %State{conn_state: :not_in_transaction} = state) do
    {:ok, state} = rollback_transaction(state)
    Connection.disconnect(exc, state.internal_state)
  end

  @impl DBConnection
  def handle_begin(_opts, %State{conn_state: conn_state} = state)
      when conn_state in [:in_transaction, :in_failed_transaction] do
    {status(state), state}
  end

  @impl DBConnection
  def handle_begin(_opts, %State{} = state) do
    declare_savepoint(state)
  end

  @impl DBConnection
  def handle_close(query, opts, %State{} = state) do
    with {reason, result, internal_state} <-
           Connection.handle_close(query, opts, state.internal_state) do
      {reason, result, %State{state | internal_state: internal_state}}
    end
  end

  @impl DBConnection
  def handle_commit(_opts, %State{conn_state: conn_state} = state)
      when conn_state in [:not_in_transaction, :in_failed_transaction] do
    {status(state), state}
  end

  @impl DBConnection
  def handle_commit(_opts, %State{} = state) do
    release_savepoint(state)
  end

  @impl DBConnection
  def handle_deallocate(_query, _cursor, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_deallocate/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_declare(_query, _params, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_declare/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :start_sandbox_transaction} = request,
        _params,
        _opts,
        %State{} = state
      ) do
    with {:ok, state} <- start_transaction(state) do
      {:ok, request, :ok, state}
    end
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :rollback_sandbox_transaction} = request,
        _params,
        _opts,
        %State{} = state
      ) do
    with {:ok, state} <- rollback_transaction(state) do
      {:ok, request, :ok, state}
    end
  end

  @impl DBConnection
  def handle_execute(query, params, opts, %State{} = state) do
    case Connection.handle_execute(query, params, opts, state.internal_state) do
      {:ok, query, result, internal_state} ->
        {:ok, query, result, %State{state | internal_state: internal_state}}

      {reason, exc, internal_state} ->
        {reason, exc, %State{state | internal_state: internal_state}}
    end
  end

  @impl DBConnection
  def handle_fetch(_query, _cursor, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_fetch/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_prepare(query, opts, state) do
    case Connection.handle_prepare(query, opts, state.internal_state) do
      {:ok, query, internal_state} ->
        {:ok, query, %State{state | internal_state: internal_state}}

      {reason, exc, internal_state} ->
        {reason, exc, %State{state | internal_state: internal_state}}
    end
  end

  @impl DBConnection
  def handle_rollback(_opts, %State{conn_state: conn_state} = state)
      when conn_state == :not_in_transaction do
    {status(state), state}
  end

  @impl DBConnection
  def handle_rollback(_opts, state) do
    rollback_to_savepoint(state)
  end

  @impl DBConnection
  def handle_status(_opts, state) do
    {status(state), state}
  end

  @impl DBConnection
  def ping(state) do
    {:ok, state}
  end

  defp start_transaction(state) do
    case Connection.handle_begin([], state.internal_state) do
      {:ok, _result, internal_state} ->
        {:ok, %State{state | conn_state: :not_in_transaction, internal_state: internal_state}}

      {_status, internal_state} ->
        exc = EdgeDB.ClientError.new("unable to start transaction for sandbox connection")
        {:error, exc, %State{conn_state: :not_in_transaction, internal_state: internal_state}}

      {:disconnect, exc, internal_state} ->
        {:disconnect, exc,
         %State{conn_state: :not_in_transaction, internal_state: internal_state}}
    end
  end

  defp rollback_transaction(
         %State{internal_state: %Connection.State{server_state: :not_in_transaction}} = state
       ) do
    {:ok, state}
  end

  defp rollback_transaction(%State{} = state) do
    case Connection.handle_rollback([], state.internal_state) do
      {:ok, _result, internal_state} ->
        {:ok, %State{state | internal_state: internal_state}}

      {_status, internal_state} ->
        exc = EdgeDB.ClientError.new("unable to rollback transaction for sandbox connection")
        {:error, exc, %State{conn_state: :in_failed_transaction, internal_state: internal_state}}

      {:disconnect, exc, internal_state} ->
        exc =
          EdgeDB.ClientError.new(
            "unable to rollback transaction for sandbox connection: #{exc.message}"
          )

        {:disconnect, exc,
         %State{conn_state: :in_failed_transaction, internal_state: internal_state}}
    end
  end

  defp declare_savepoint(%State{} = state) do
    {:ok, _request, next_savepoint_id, internal_state} =
      Connection.handle_execute(
        %InternalRequest{request: :next_savepoint},
        [],
        [],
        state.internal_state
      )

    savepoint_name = "edgedb_elixir_sandbox_#{next_savepoint_id}"

    statement = QueryBuilder.declare_savepoint_statement(savepoint_name)

    case Connection.handle_execute(
           %InternalRequest{request: :execute_script_flow},
           %{
             statement: statement,
             headers: %{}
           },
           [],
           internal_state
         ) do
      {:ok, _request, result, internal_state} ->
        {:ok, result,
         %State{
           state
           | conn_state: :in_transaction,
             internal_state: internal_state,
             savepoint: savepoint_name
         }}

      {reason, exc, internal_state} ->
        {reason, exc, %State{state | internal_state: internal_state}}
    end
  end

  defp release_savepoint(%State{} = state) do
    statement = QueryBuilder.release_savepoint_statement(state.savepoint)

    case Connection.handle_execute(
           %InternalRequest{request: :execute_script_flow},
           %{
             statement: statement,
             headers: %{}
           },
           [],
           state.internal_state
         ) do
      {:ok, _request, result, internal_state} ->
        {:ok, result,
         %State{
           state
           | conn_state: :not_in_transaction,
             internal_state: internal_state,
             savepoint: nil
         }}

      {reason, exc, internal_state} ->
        {reason, exc, %State{state | internal_state: internal_state}}
    end
  end

  defp rollback_to_savepoint(%State{} = state) do
    statement = QueryBuilder.rollback_to_savepoint_statement(state.savepoint)

    case Connection.handle_execute(
           %InternalRequest{request: :execute_script_flow},
           %{
             statement: statement,
             headers: %{}
           },
           [],
           state.internal_state
         ) do
      {:ok, _request, result, internal_state} ->
        {:ok, result,
         %State{
           state
           | conn_state: :not_in_transaction,
             internal_state: internal_state,
             savepoint: nil
         }}

      {reason, exc, internal_state} ->
        {reason, exc, %State{state | internal_state: internal_state}}
    end
  end

  defp status(%State{conn_state: :not_in_transaction}) do
    :idle
  end

  defp status(%State{conn_state: :in_transaction}) do
    :transaction
  end

  defp status(%State{conn_state: :in_failed_transaction}) do
    :error
  end
end
