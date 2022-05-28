defmodule Tests.EdgeDB.Protocol.Codecs.NamedTupleTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding named tuple value", %{conn: conn} do
    value = new_named_tuple([{"a", 1}, {"b", "string"}, {"c", true}, {"d", 1.0}])

    assert ^value =
             EdgeDB.query_single!(conn, "select (a := 1, b := \"string\", c := true, d := 1.0)")
  end

  defp new_named_tuple(items) do
    fields_ordering =
      items
      |> Enum.with_index()
      |> Enum.map(fn {{name, _value}, index} ->
        {index, name}
      end)
      |> Enum.into(%{})

    %EdgeDB.NamedTuple{
      __items__: Enum.into(items, %{}),
      __fields_ordering__: fields_ordering
    }
  end
end
