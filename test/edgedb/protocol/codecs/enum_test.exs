defmodule Tests.EdgeDB.Protocol.Codecs.EnumTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Errors

  setup :edgedb_connection

  test "decoding enum value", %{conn: conn} do
    value = "Green"
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <Color>'Green'")
  end

  test "encoding string to enum value", %{conn: conn} do
    value = "Green"
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <Color>$0", [value])
  end

  test "error when encoding not member element to enum value", %{conn: conn} do
    value = "White"

    assert_raise Errors.InvalidArgumentError,
                 "unable to encode #{inspect(value)} as enum: #{inspect(value)} is not member of enum",
                 fn ->
                   EdgeDB.query_one(conn, "SELECT <Color>$0", [value])
                 end
  end
end
