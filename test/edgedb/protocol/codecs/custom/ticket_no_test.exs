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

  test "decoding default::TicketNo value", %{client: client} do
    value = %TicketNo{number: 42}
    assert ^value = EdgeDB.query_single!(client, "select <TicketNo>42")
  end

  test "encoding default::TicketNo value", %{client: client} do
    value = %TicketNo{number: 42}
    assert ^value = EdgeDB.query_single!(client, "select <TicketNo>$0", [value])
  end
end
