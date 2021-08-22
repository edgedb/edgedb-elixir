defmodule EdgeDB.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      defp edgedb_connection(_context) do
        {:ok, conn} = start_supervised(EdgeDB)

        %{conn: conn}
      end
    end
  end
end
