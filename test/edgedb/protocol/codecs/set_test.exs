defmodule Tests.EdgeDB.Protocol.Codecs.SetTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding set value", %{client: client} do
    value = new_set([1, 2, 3])
    assert {:ok, ^value} = EdgeDB.query(client, "select {1, 2, 3}")
  end

  defp new_set(elements) do
    %EdgeDB.Set{items: elements}
  end
end
