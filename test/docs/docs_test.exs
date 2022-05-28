defmodule Tests.DocsTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  setup %{conn: conn} do
    conn
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

  defp drop_tickets(conn) do
    EdgeDB.query!(conn, "delete Ticket")

    conn
  end

  defp drop_persons(conn) do
    EdgeDB.query!(conn, "delete Person")

    conn
  end

  defp add_person(conn) do
    EdgeDB.query!(conn, """
    insert Person {
      first_name := 'Daniel',
      middle_name := 'Jacob',
      last_name := 'Radcliffe',
      image := ''
    };
    """)

    conn
  end
end
