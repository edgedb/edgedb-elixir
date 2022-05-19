defmodule Tests.EdgeDB.Protocol.Codecs.SetTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding set value", %{conn: conn} do
    value = new_set([1, 2, 3])
    assert {:ok, ^value} = EdgeDB.query(conn, "SELECT {1, 2, 3}")
  end

  defp new_set(elements) do
    %EdgeDB.Set{__items__: elements}
  end
end
