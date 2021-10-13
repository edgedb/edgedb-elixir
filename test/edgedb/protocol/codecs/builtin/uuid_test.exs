defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.UUIDTest do
  use Tests.Support.EdgeDBCase

  alias EdgeDB.Protocol.Error

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
      assert_raise Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <uuid>$0", ["something"])
      end

    assert exc == Error.invalid_argument_error("unable to encode \"something\" as std::uuid")
  end
end
