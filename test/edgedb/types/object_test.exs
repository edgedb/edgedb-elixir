defmodule Tests.EdgeDB.Types.ObjectTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  describe "EdgeDB.Object.properties/2" do
    test "returns list of object properties names", %{client: client} do
      rollback(client, fn client ->
        EdgeDB.query!(client, """
        insert v1::User {
          name := "username",
        }
        """)

        user_properties =
          client
          |> EdgeDB.query_required_single!("select v1::User { name } limit 1")
          |> EdgeDB.Object.properties()
          |> MapSet.new()

        expected_properties = MapSet.new(["name"])
        assert MapSet.equal?(user_properties, expected_properties)
      end)
    end

    test "returns list of object properties names + id with `:id` option ", %{client: client} do
      rollback(client, fn client ->
        EdgeDB.query!(client, """
        insert v1::User {
          name := "username",
        }
        """)

        user_properties =
          client
          |> EdgeDB.query_required_single!("select v1::User { name } limit 1")
          |> EdgeDB.Object.properties(id: true)
          |> MapSet.new()

        expected_properties = MapSet.new(["id", "name"])
        assert MapSet.equal?(user_properties, expected_properties)
      end)
    end

    test "returns list of object properties names + id with `:implicit` option ", %{
      client: client
    } do
      rollback(client, fn client ->
        EdgeDB.query!(client, """
        insert v1::User {
          name := "username",
        }
        """)

        user_properties =
          client
          |> EdgeDB.query_required_single!("select v1::User { name } limit 1")
          |> EdgeDB.Object.properties(implicit: true)
          |> MapSet.new()

        expected_properties = MapSet.new(["id", "name"])
        assert MapSet.equal?(user_properties, expected_properties)
      end)
    end
  end

  describe "EdgeDB.Object.links/1" do
    test "returns list of object links names", %{client: client} do
      rollback(client, fn client ->
        EdgeDB.query!(client, """
        with
          director := (
            insert v1::Person {
              first_name := "Chris",
              middle_name := "Joseph",
              last_name := "Columbus",
            }
          ),
          actor1 := (
            first_name := "Daniel",
            middle_name := "Jacob",
            last_name := "Radcliffe",
          ),
          actor2 := (
            first_name := "Emma",
            middle_name := "Charlotte Duerre",
            last_name := "Watson",
          )
        insert v1::Movie {
          title := "Harry Potter and the Philosopher's Stone",
          year := 2001,
          description := $$
            Late one night, Albus Dumbledore and Minerva McGonagall, professors at Hogwarts School of Witchcraft and Wizardry, along with the school's groundskeeper Rubeus Hagrid, deliver a recently orphaned infant named Harry Potter to his only remaining relatives, the Dursleys....
          $$,
          directors := director,
          actors := (
            for a in {(1, actor1), (2, actor2)}
            union (
              insert v1::Person {
                first_name := a.1.first_name,
                middle_name := a.1.middle_name,
                last_name := a.1.last_name,
                @list_order := a.0
              }
            )
          )
        }
        """)

        movie_links =
          client
          |> EdgeDB.query_required_single!("""
          select v1::Movie {
            title,
            directors,
            actors: {
              @list_order
            } order by @list_order,
          } limit 1
          """)
          |> EdgeDB.Object.links()
          |> MapSet.new()

        expected_links = MapSet.new(["directors", "actors"])
        assert MapSet.equal?(movie_links, expected_links)
      end)
    end
  end

  describe "EdgeDB.Object.link_properties/1" do
    test "returns list of object link properties names", %{client: client} do
      rollback(client, fn client ->
        EdgeDB.query!(client, """
        with
          director := (
            insert v1::Person {
              first_name := "Chris",
              middle_name := "Joseph",
              last_name := "Columbus",
            }
          ),
          actor1 := (
            first_name := "Daniel",
            middle_name := "Jacob",
            last_name := "Radcliffe",
          ),
          actor2 := (
            first_name := "Emma",
            middle_name := "Charlotte Duerre",
            last_name := "Watson",
          )
        insert v1::Movie {
          title := "Harry Potter and the Philosopher's Stone",
          year := 2001,
          description := $$
            Late one night, Albus Dumbledore and Minerva McGonagall, professors at Hogwarts School of Witchcraft and Wizardry, along with the school's groundskeeper Rubeus Hagrid, deliver a recently orphaned infant named Harry Potter to his only remaining relatives, the Dursleys....
          $$,
          directors := director,
          actors := (
            for a in {(1, actor1), (2, actor2)}
            union (
              insert v1::Person {
                first_name := a.1.first_name,
                middle_name := a.1.middle_name,
                last_name := a.1.last_name,
                @list_order := a.0
              }
            )
          )
        }
        """)

        movie =
          EdgeDB.query_required_single!(client, """
          select v1::Movie {
            title,
            directors,
            actors: {
              @list_order
            } order by @list_order,
          } limit 1
          """)

        actors = movie[:actors]

        for actor <- actors do
          actor_link_properties =
            actor
            |> EdgeDB.Object.link_properties()
            |> MapSet.new()

          expected_link_properties = MapSet.new(["@list_order"])
          assert MapSet.equal?(actor_link_properties, expected_link_properties)
        end
      end)
    end
  end

  describe "EdgeDB.Object.to_map/1" do
    test "returns map converted from object", %{client: client} do
      object =
        EdgeDB.query_required_single!(client, """
         select schema::Property {
             name,
             annotations: {
               name,
               @value
             }
         }
         filter .name = 'listen_port' and .source.name = 'cfg::Config'
         limit 1
        """)

      assert %{
               "name" => "listen_port",
               "annotations" => [
                 %{
                   "name" => "cfg::system",
                   "@value" => "true"
                 }
               ]
             } == EdgeDB.Object.to_map(object)
    end
  end
end
