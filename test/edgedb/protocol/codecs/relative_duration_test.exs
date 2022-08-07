defmodule Tests.EdgeDB.Protocol.Codecs.RelativeDurationTest do
  use Tests.Support.EdgeDBCase

  alias EdgeDB.RelativeDuration

  setup :edgedb_client

  test "decoding cal::relative_duration value", %{client: client} do
    assert %RelativeDuration{months: 12} =
             EdgeDB.query_single!(client, "select <cal::relative_duration>'1 year'")
  end

  test "encoding cal::relative_duration value", %{client: client} do
    value = %RelativeDuration{
      days: 25,
      months: 84,
      microseconds: 42
    }

    assert ^value = EdgeDB.query_single!(client, "select <cal::relative_duration>$0", [value])
  end
end
