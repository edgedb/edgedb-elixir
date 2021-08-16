defmodule EdgeDB.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      defp edgedb_connection(_context) do
        {:ok, conn} = EdgeDB.start_link(user: "edgedb_trust", port: 10_700)

        %{conn: conn}
      end
    end
  end
end
