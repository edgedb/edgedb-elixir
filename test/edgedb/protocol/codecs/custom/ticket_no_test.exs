defmodule Tests.EdgeDB.Protocol.Codecs.Custom.TicketNoTest do
  use Tests.Support.EdgeDBCase

  alias Tests.Support.{
    Codecs,
    TicketNo
  }

  setup do
    {:ok, conn} =
      start_supervised(
        {EdgeDB, codecs: [Codecs.TicketNo], show_sensitive_data_on_connection_error: true}
      )

    %{conn: conn}
  end

  test "decoding default::TicketNo value", %{conn: conn} do
    value = %TicketNo{number: 42}

    assert ^value = EdgeDB.query_single!(conn, "select <TicketNo>42")
  end

  test "encoding default::TicketNo value", %{conn: conn} do
    value = %TicketNo{number: 42}
    assert ^value = EdgeDB.query_single!(conn, "select <TicketNo>$0", [value])
  end
end
