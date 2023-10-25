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

  skip_before(version: 2)
  doctest EdgeDB.DateDuration

  skip_before(version: 2)
  doctest EdgeDB.Range

  defp drop_tickets(client) do
    EdgeDB.query!(client, "delete v1::Ticket")

    client
  end

  defp drop_persons(client) do
    EdgeDB.query!(client, "delete v1::Person")

    client
  end

  defp add_person(client) do
    EdgeDB.query!(client, """
    insert v1::Person {
      first_name := 'Daniel',
      middle_name := 'Jacob',
      last_name := 'Radcliffe',
    };
    """)

    client
  end
end
