defmodule Tests.EdgeDB.Protocol.Codecs.VectorTest do
  use Tests.Support.EdgeDBCase

  skip_before(version: 3, scope: :module)

  setup :edgedb_client

  test "decoding vector value", %{client: client} do
    value = [1.5, 2.0, 4.5]

    assert ^value = EdgeDB.query_single!(client, "select <ext::pgvector::vector>[1.5, 2.0, 4.5]")
  end

  test "encoding vector value", %{client: client} do
    value = [1.5, 2.0, 4.5]
    assert ^value = EdgeDB.query_single!(client, "select <ext::pgvector::vector>$0", [value])
  end

  test "decoding custom scalar vector value", %{client: client} do
    value =
      [1.5]
      |> List.duplicate(1602)
      |> List.flatten()

    assert ^value = EdgeDB.query_single!(client, "select <ExVector>array_fill(1.5, 1602)")
  end

  test "encoding custom scalar vector value", %{client: client} do
    value =
      [1.5]
      |> List.duplicate(1602)
      |> List.flatten()

    assert ^value = EdgeDB.query_single!(client, "select <ExVector>$0", [value])
  end

  test "encoding empty vector value results in an error", %{client: client} do
    assert {:error, %EdgeDB.Error{}} =
             EdgeDB.query_single(client, "select <ext::pgvector::vector>$0", [])
  end
end
