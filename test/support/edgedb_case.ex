defmodule Tests.Support.EdgeDBCase do
  use ExUnit.CaseTemplate

  import Mox

  alias Tests.Support.Mocks

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

  @spec edgedb_connection(term()) :: map()
  def edgedb_connection(_context) do
    {:ok, conn} =
      start_supervised(
        {EdgeDB,
         backoff_type: :stop, max_restarts: 0, show_sensitive_data_on_connection_error: true}
      )

    %{conn: conn}
  end

  @spec setup_stubs_fallbacks(term()) :: :ok
  def setup_stubs_fallbacks(_context) do
    stub_with(Mocks.FileMock, Mocks.Stubs.FileStub)
    stub_with(Mocks.PathMock, Mocks.Stubs.PathStub)
    stub_with(Mocks.SystemMock, Mocks.Stubs.SystemStub)

    :ok
  end
end
