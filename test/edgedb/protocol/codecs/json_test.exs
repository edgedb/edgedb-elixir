defmodule Tests.EdgeDB.Protocol.Codecs.JSONTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  test "decoding std::json value", %{conn: conn} do
    value = %{
      "field" => "value"
    }

    assert ^value = EdgeDB.query_single!(conn, "select <json>to_json('{\"field\": \"value\"}')")
  end

  test "encoding std::json value", %{conn: conn} do
    value = %{
      "field" => "value"
    }

    assert ^value = EdgeDB.query_single!(conn, "select <json>$0", [value])
  end
end
