defmodule Tests.EdgeDB.Protocol.Codecs.Custom.TicketNoTest do
  use Tests.Support.EdgeDBCase

  alias Tests.Support.{
    Codecs,
    TicketNo
  }

  setup do
    {:ok, client} =
      start_supervised(
        {EdgeDB,
         max_concurrency: 1,
         tls_security: :insecure,
         codecs: [Codecs.TicketNo],
         show_sensitive_data_on_connection_error: true}
      )

    %{client: client}
  end

  test "decoding v1::TicketNo value", %{client: client} do
    value = %TicketNo{number: 42}
    assert ^value = EdgeDB.query_single!(client, "select <v1::TicketNo>42")
  end

  test "encoding v1::TicketNo value", %{client: client} do
    value = %TicketNo{number: 42}
    assert ^value = EdgeDB.query_single!(client, "select <v1::TicketNo>$0", [value])
  end
end
