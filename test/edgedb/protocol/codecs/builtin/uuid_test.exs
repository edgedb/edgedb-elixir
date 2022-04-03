defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.UUIDTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding std::uuid value", %{conn: conn} do
    value = "380ed95c-6e36-40f9-b313-54d000fbb144"
    assert ^value = EdgeDB.query_single!(conn, "SELECT <uuid>'#{value}'")
  end

  test "encoding std::uuid value", %{conn: conn} do
    value = "380ed95c-6e36-40f9-b313-54d000fbb144"
    assert ^value = EdgeDB.query_single!(conn, "SELECT <uuid>$0", [value])
  end

  test "error when passing non UUID as std::uuid argument", %{conn: conn} do
    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <uuid>$0", ["something"])
      end

    assert exc ==
             EdgeDB.Error.invalid_argument_error(
               "value can not be encoded as std::uuid: Invalid argument; Not a valid UUID: #{"something"}"
             )
  end
end
