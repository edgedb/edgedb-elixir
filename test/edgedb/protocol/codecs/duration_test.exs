defmodule Tests.EdgeDB.Protocol.Codecs.DurationTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding std::duration value", %{conn: conn} do
    value = 175_507_600_000

    assert {:ok, ^value} =
             EdgeDB.query_one(conn, "SELECT <duration>'48 hours 45 minutes 7.6 seconds'")
  end

  test "encoding std::duration value", %{conn: conn} do
    value = 175_507_600_000

    assert {:ok, true} =
             EdgeDB.query_one(
               conn,
               "SELECT <duration>'48 hours 45 minutes 7.6 seconds' = <duration>$0",
               [value]
             )
  end
end
