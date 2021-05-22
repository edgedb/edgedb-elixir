defmodule Tests.EdgeDB.Protocol.Codecs.UUIDTest do
  use EdgeDB.Case

  alias EdgeDB.Protocol.Errors

  setup :edgedb_connection

  test "decoding std::uuid value", %{conn: conn} do
    value = "380ed95c-6e36-40f9-b313-54d000fbb144"
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <uuid>'#{value}'")
  end

  test "encoding std::uuid value", %{conn: conn} do
    value = "380ed95c-6e36-40f9-b313-54d000fbb144"
    assert {:ok, ^value} = EdgeDB.query_one(conn, "SELECT <uuid>$0", [value])
  end

  test "error when passing non UUID as std::uuid argument", %{conn: conn} do
    assert_raise Errors.InvalidArgumentError,
                 "unable to encode \"something\" as std::uuid",
                 fn ->
                   EdgeDB.query_one(conn, "SELECT <uuid>$0", ["something"])
                 end
  end
end
