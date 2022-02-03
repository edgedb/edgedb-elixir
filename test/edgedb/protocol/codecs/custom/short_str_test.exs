defmodule Tests.EdgeDB.Protocol.Codecs.Custom.ShortStrTest do
  use Tests.Support.EdgeDBCase

  alias Tests.Support.Codecs

  setup do
    {:ok, conn} =
      start_supervised(
        {EdgeDB, codecs: [Codecs.ShortStr], show_sensitive_data_on_connection_error: true}
      )

    %{conn: conn}
  end

  test "decoding default::short_str value", %{conn: conn} do
    value = "short"

    assert ^value = EdgeDB.query_single!(conn, "SELECT <short_str>\"short\"")
  end

  test "encoding default::short_str value", %{conn: conn} do
    value = "short"
    assert ^value = EdgeDB.query_single!(conn, "SELECT <short_str>$0", [value])
  end

  test "error when passing value that can't be encoded by custom codec as default::short_str argument",
       %{conn: conn} do
    value = "too long string"

    exc =
      assert_raise EdgeDB.Error, fn ->
        EdgeDB.query_single!(conn, "SELECT <short_str>$0", [value])
      end

    assert exc == EdgeDB.Error.invalid_argument_error("string is too long")
  end
end
