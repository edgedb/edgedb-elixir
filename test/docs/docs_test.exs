defmodule Tests.DocsTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  setup %{client: client} do
    client
    |> drop_tickets()
    |> drop_persons()
    |> add_person()

    :ok
  end

  doctest EdgeDB
  doctest EdgeDB.ConfigMemory
  doctest EdgeDB.NamedTuple
  doctest EdgeDB.Object
  doctest EdgeDB.RelativeDuration
  doctest EdgeDB.Set

  defp drop_tickets(client) do
    EdgeDB.query!(client, "delete Ticket")

    client
  end

  defp drop_persons(client) do
    EdgeDB.query!(client, "delete Person")

    client
  end

  defp add_person(client) do
    EdgeDB.query!(client, """
    insert Person {
      first_name := 'Daniel',
      middle_name := 'Jacob',
      last_name := 'Radcliffe',
      image := ''
    };
    """)

    client
  end
end
