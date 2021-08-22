defmodule Tests.EdgeDB.Protocol.Codecs.Custom.TicketNoTest do
  use EdgeDB.Case

  alias Tests.Support.Codecs

  setup do
    {:ok, conn} = start_supervised({EdgeDB, [codecs: [Codecs.TicketNo]]})

    %{conn: conn}
  end

  test "decoding default::TicketNo value", %{conn: conn} do
    value = %Codecs.TicketNo{number: 42}

    assert ^value = EdgeDB.query_single!(conn, "SELECT <TicketNo>42")
  end

  test "encoding default::TicketNo value", %{conn: conn} do
    value = %Codecs.TicketNo{number: 42}
    assert ^value = EdgeDB.query_single!(conn, "SELECT <TicketNo>$0", [value])
  end
end
