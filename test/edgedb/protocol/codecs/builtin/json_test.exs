defmodule Tests.EdgeDB.Protocol.Codecs.Builtin.JSONTest do
  use EdgeDB.Case

  setup :edgedb_connection

  test "decoding std::json value", %{conn: conn} do
    value = %{
      "field" => "value"
    }

    assert ^value = EdgeDB.query_single!(conn, "SELECT <json>to_json('{\"field\": \"value\"}')")
  end

  test "encoding std::json value", %{conn: conn} do
    value = %{
      "field" => "value"
    }

    assert ^value = EdgeDB.query_single!(conn, "SELECT <json>$0", [value])
  end
end
