defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.NamedTupleTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding named tuple value", %{conn: conn} do
    value =
      EdgeDB.NamedTuple.new(%{
        "a" => 1,
        "b" => "string",
        "c" => true,
        "d" => 1.0
      })

    assert ^value =
             EdgeDB.query_single!(conn, "SELECT (a := 1, b := \"string\", c := true, d := 1.0)")
  end
end
