defmodule EdgeDB.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      defp edgedb_connection(_context) do
        {:ok, conn} = start_supervised({EdgeDB, [user: "edgedb_trust"]})

        %{conn: conn}
      end
    end
  end
end
