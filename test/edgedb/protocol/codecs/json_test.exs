defmodule Tests.EdgeDB.Protocol.Codecs.JSONTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  test "decoding std::json value", %{client: client} do
    value = %{
      "field" => "value"
    }

    assert ^value = EdgeDB.query_single!(client, "select <json>to_json('{\"field\": \"value\"}')")
  end

  test "encoding std::json value", %{client: client} do
    value = %{
      "field" => "value"
    }

    assert ^value = EdgeDB.query_single!(client, "select <json>$0", [value])
  end
end
