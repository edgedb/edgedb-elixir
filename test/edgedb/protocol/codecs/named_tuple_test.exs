defmodule Tests.EdgeDB.Protocol.Codecs.NamedTupleTest do
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

    assert {:ok, ^value} =
             EdgeDB.query_single(conn, "SELECT (a := 1, b := \"string\", c := true, d := 1.0)")
  end
end
