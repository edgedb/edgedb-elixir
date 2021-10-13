defmodule Tests.Connection.ConfigTest do
  use Tests.Support.EdgeDBCase, async: false

  alias EdgeDB.Connection.Config

  describe "EdgeDB.Connection.Config.connect_opts/1" do
    test "returns additional options along with connection options" do
      options =
        Config.connect_opts(
          dsn: "edgedb://edgedb:edgedb@localhost/5656/edgedb",
          show_sensitive_data_on_connection_error: true
        )

      assert Keyword.has_key?(options, :show_sensitive_data_on_connection_error)
    end
  end
end
