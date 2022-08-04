defmodule Tests.Support.EdgeDBCase do
  use ExUnit.CaseTemplate

  import Mox

  alias Tests.Support.Mocks

  @dialyzer {:nowarn_function, rollback: 2}

  using do
    quote do
      import Mox

      import unquote(__MODULE__)

      setup [
        :setup_stubs_fallbacks,
        :verify_on_exit!
      ]
    end
  end

  defmacro skip_before(opts \\ []) do
    {edgedb_version, ""} =
      "EDGEDB_VERSION"
      |> System.get_env("9999")
      |> Integer.parse()

    requested_version = opts[:version]

    tag_type =
      case opts[:scope] do
        :module ->
          :moduletag

        :describe ->
          :describetag

        _other ->
          :tag
      end

    if edgedb_version < requested_version do
      {:@, [], [{tag_type, [], [:skip]}]}
    else
      {:__block__, [], []}
    end
  end

  @spec edgedb_connection(term()) :: map()
  def edgedb_connection(_context) do
    {:ok, conn} =
      start_supervised(
        {EdgeDB,
         backoff_type: :stop, max_restarts: 0, show_sensitive_data_on_connection_error: true}
      )

    %{conn: conn}
  end

  @spec reconnectable_edgedb_connection(term()) :: map()
  def reconnectable_edgedb_connection(_context) do
    spec =
      EdgeDB.child_spec(
        show_sensitive_data_on_connection_error: true,
        connection_listeners: [self()]
      )

    spec = %{spec | id: "reconnectable_edgedb_connection"}

    {:ok, conn} = start_supervised(spec)

    assert_receive {:connected, conn_pid}, 1000

    %{
      mod_state: %{
        state: %EdgeDB.Connection.State{
          socket: socket
        }
      }
    } = :sys.get_state(conn_pid)

    %{conn: conn, pid: conn_pid, socket: socket}
  end

  @spec rollback(EdgeDB.connection(), (EdgeDB.connection() -> any())) :: :ok
  def rollback(conn, callback) do
    assert {:error, :expected} =
             EdgeDB.transaction(conn, fn conn ->
               callback.(conn)

               EdgeDB.rollback(conn, reason: :expected)
             end)

    :ok
  end

  @spec setup_stubs_fallbacks(term()) :: :ok
  def setup_stubs_fallbacks(_context) do
    stub_with(Mocks.FileMock, Mocks.Stubs.FileStub)
    stub_with(Mocks.SystemMock, Mocks.Stubs.SystemStub)
    stub_with(Mocks.PathMock, Mocks.Stubs.PathStub)

    :ok
  end
end
