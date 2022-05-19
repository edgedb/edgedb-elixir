defmodule Tests.EdgeDB.Protocol.Codecs.NamedTupleTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding named tuple value", %{conn: conn} do
    value = new_named_tuple([{"a", 1}, {"b", "string"}, {"c", true}, {"d", 1.0}])

    assert ^value =
             EdgeDB.query_single!(conn, "SELECT (a := 1, b := \"string\", c := true, d := 1.0)")
  end

  test "encoding passed arguments in right order", %{conn: conn} do
    assert {1, 2} =
             EdgeDB.query_single!(conn, "SELECT (<int64>$arg1, <int64>$arg2)", arg2: 2, arg1: 1)
  end

  test "encoding nil as valid argument", %{conn: conn} do
    assert set = %EdgeDB.Set{} = EdgeDB.query!(conn, "SELECT <OPTIONAL str>$arg", arg: nil)
    assert EdgeDB.Set.empty?(set)
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
