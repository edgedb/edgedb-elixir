defmodule Tests.EdgeDB.Connection.StateTest do
  use Tests.Support.EdgeDBCase, async: false

  skip_before(version: 2, scope: :module)

  describe "EdgeDB.start_link/1 with state option" do
    setup do
      current_user = "current_user"

      # 48:45:07:6
      duration = Timex.Duration.from_microseconds(175_507_600_000)

      state =
        %EdgeDB.Client.State{}
        |> EdgeDB.Client.State.with_default_module("schema")
        |> EdgeDB.Client.State.with_module_aliases(%{"math_alias" => "math", "cfg_alias" => "cfg"})
        |> EdgeDB.Client.State.with_globals(%{"v2::current_user" => current_user})
        |> EdgeDB.Client.State.with_config(%{query_execution_timeout: duration})

      %{state: state, current_user: current_user, duration: duration}
    end

    test "passes state as default state to connection", %{
      state: state,
      current_user: current_user,
      duration: duration
    } do
      {:ok, client} =
        start_supervised(
          {EdgeDB,
           tls_security: :insecure,
           max_concurrency: 1,
           show_sensitive_data_on_connection_error: true,
           client_state: state}
        )

      object =
        EdgeDB.query_required_single!(client, """
          with
            config := (select cfg_alias::Config limit 1),
            abs_value := math_alias::abs(-1),
            user_object_type := (select ObjectType filter .name = 'v1::User' limit 1)
          select {
            current_user := global v2::current_user,
            config_query_execution_timeout := config.query_execution_timeout,
            math_abs_value := abs_value,
            user_type := user_object_type { name }
          }
        """)

      assert object[:current_user] == current_user
      assert object[:config_query_execution_timeout] == duration
      assert object[:math_abs_value] == 1
      assert object[:user_type][:name] == "v1::User"
    end
  end

  describe "EdgeDB.start_link/1 with state option in config" do
    setup do
      current_user = "current_user"

      # 48:45:07:6
      duration = Timex.Duration.from_microseconds(175_507_600_000)

      state =
        %EdgeDB.Client.State{}
        |> EdgeDB.Client.State.with_default_module("schema")
        |> EdgeDB.Client.State.with_module_aliases(%{"math_alias" => "math", "cfg_alias" => "cfg"})
        |> EdgeDB.Client.State.with_globals(%{"v2::current_user" => current_user})
        |> EdgeDB.Client.State.with_config(query_execution_timeout: duration)

      Application.put_env(:edgedb, :client_state, state)
      on_exit(fn -> Application.delete_env(:edgedb, :client_state) end)

      %{current_user: current_user, duration: duration}
    end

    test "passes state from config as default state to connection", %{
      current_user: current_user,
      duration: duration
    } do
      {:ok, client} =
        start_supervised(
          {EdgeDB, tls_security: :insecure, max_concurrency: 1, show_sensitive_data_on_connection_error: true}
        )

      object =
        EdgeDB.query_required_single!(client, """
          with
            config := (select cfg_alias::Config limit 1),
            abs_value := math_alias::abs(-1),
            user_object_type := (select ObjectType filter .name = 'v1::User' limit 1)
          select {
            current_user := global v2::current_user,
            config_query_execution_timeout := config.query_execution_timeout,
            math_abs_value := abs_value,
            user_type := user_object_type { name }
          }
        """)

      assert object[:current_user] == current_user
      assert object[:config_query_execution_timeout] == duration
      assert object[:math_abs_value] == 1
      assert object[:user_type][:name] == "v1::User"
    end
  end
end
