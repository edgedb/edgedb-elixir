defmodule Tests.EdgeDB.Protocol.Codecs.Custom.NotRegisteredStringTest do
  use Tests.Support.EdgeDBCase

  import ExUnit.CaptureLog

  alias Tests.Support.Codecs

  test "skipping codecs which type names can't be fetched from database" do
    assert capture_log(fn ->
             {:ok, client} =
               start_supervised(
                 {EdgeDB,
                  tls_security: :insecure,
                  max_concurrency: 1,
                  codecs: [Codecs.NotRegisteredString],
                  show_sensitive_data_on_connection_error: true}
               )

             _result = EdgeDB.query!(client, "select 1")
           end) =~
             "skip registration of codec for unknown type with name \"default::not_registered_string\""
  end
end
