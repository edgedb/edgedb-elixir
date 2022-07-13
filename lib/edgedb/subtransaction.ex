defmodule EdgeDB.Subtransaction do
  @moduledoc false

  use DBConnection

  alias EdgeDB.Connection.{
    InternalRequest,
    QueryBuilder
  }

  alias EdgeDB.Protocol.Enums
  alias EdgeDB.Subtransaction.State

  defmodule State do
    @moduledoc false

    defstruct [
      :conn,
      conn_state: :not_in_transaction,
      savepoint: nil
    ]

    @type t() :: %__MODULE__{
            conn: DBConnection.t(),
            conn_state: Enums.transaction_state(),
            savepoint: String.t() | nil
          }
  end

  @impl DBConnection
  def checkout(state) do
    {:ok, state}
  end

  @impl DBConnection
  def connect(opts \\ []) do
    conn = opts[:conn]

    {:ok, %State{conn: conn}}
  end

  @impl DBConnection
  def disconnect(_exc, _state) do
    :ok
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
  def handle_close(_query, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_close/3 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_commit(_opts, %State{conn_state: conn_state} = state)
      when conn_state in [:not_in_transaction, :in_failed_transaction] do
    {status(state), state}
  end

  @impl DBConnection
  def handle_commit(_opts, state) do
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
  def handle_execute(%EdgeDB.Query{} = query, params, opts, %State{} = state) do
    case DBConnection.execute(
           state.conn,
           %InternalRequest{request: :execute_granular_flow},
           %{query: query, params: params},
           opts
         ) do
      {:ok, query, result} ->
        {:ok, query, result, state}

      {:error, exc} ->
        {:error, exc, state}
    end
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :is_subtransaction} = request,
        _params,
        _opts,
        %State{} = state
      ) do
    {:ok, request, true, state}
  end

  @impl DBConnection
  def handle_execute(
        %InternalRequest{request: :rollback} = request,
        _params,
        opts,
        %State{} = state
      ) do
    case handle_rollback(opts, state) do
      {:ok, result, state} ->
        {:ok, request, result, state}

      {:error, exc, state} ->
        {:error, exc, state}
    end
  end

  @impl DBConnection
  def handle_execute(%InternalRequest{} = request, params, opts, %State{} = state) do
    case DBConnection.execute(state.conn, request, params, opts) do
      {:ok, query, result} ->
        {:ok, query, result, state}

      {:error, exc} ->
        {:error, exc, state}
    end
  end

  @impl DBConnection
  def handle_fetch(_query, _cursor, _opts, state) do
    exc = EdgeDB.InterfaceError.new("handle_fetch/4 callback hasn't been implemented")
    {:error, exc, state}
  end

  @impl DBConnection
  def handle_prepare(%EdgeDB.Query{} = query, opts, %State{} = state) do
    case DBConnection.prepare(state.conn, query, opts) do
      {:ok, query} ->
        {:ok, query, state}

      {:error, exc} ->
        {:error, exc, state}
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

  defp declare_savepoint(%State{} = state) do
    next_savepoint_id =
      DBConnection.execute!(state.conn, %InternalRequest{request: :next_savepoint}, [], [])

    savepoint_name = "edgedb_elixir_#{next_savepoint_id}"

    statement = QueryBuilder.declare_savepoint_statement(savepoint_name)

    query = %EdgeDB.Query{
      statement: statement,
      output_format: :none,
      capabilities: [:transaction]
    }

    case DBConnection.execute(state.conn, %InternalRequest{request: :execute_script_flow}, %{
           statement: statement,
           headers: %{},
           query: query,
           params: []
         }) do
      {:ok, _query, result} ->
        {:ok, result,
         %State{
           state
           | conn_state: :in_transaction,
             savepoint: savepoint_name
         }}

      {:error, exc} ->
        {:error, exc, state}
    end
  end

  defp release_savepoint(%State{} = state) do
    statement = QueryBuilder.release_savepoint_statement(state.savepoint)

    query = %EdgeDB.Query{
      statement: statement,
      output_format: :none,
      capabilities: [:transaction]
    }

    case DBConnection.execute(state.conn, %InternalRequest{request: :execute_script_flow}, %{
           statement: statement,
           headers: %{},
           query: query,
           params: []
         }) do
      {:ok, _query, result} ->
        {:ok, result,
         %State{
           state
           | savepoint: nil
         }}

      {:error, exc} ->
        {:error, exc, state}
    end
  end

  defp rollback_to_savepoint(%State{} = state) do
    statement = QueryBuilder.rollback_to_savepoint_statement(state.savepoint)

    query = %EdgeDB.Query{
      statement: statement,
      output_format: :none,
      capabilities: [:transaction]
    }

    case DBConnection.execute(state.conn, %InternalRequest{request: :execute_script_flow}, %{
           statement: statement,
           headers: %{},
           query: query,
           params: []
         }) do
      {:ok, _query, result} ->
        {:ok, result, state}

      {:error, exc} ->
        {:error, exc, state}
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
