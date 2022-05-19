defmodule Tests.EdgeDB.Types.ObjectTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  describe "EdgeDB.Object.properties/2" do
    test "returns list of object properties names", %{conn: conn} do
      rollback(conn, fn conn ->
        EdgeDB.query!(conn, """
        INSERT User {
          name := "username",
          image := "http://example.com/some/url"
        }
        """)

        user_properties =
          conn
          |> EdgeDB.query_required_single!("SELECT User { name, image } LIMIT 1")
          |> EdgeDB.Object.properties()
          |> MapSet.new()

        expected_properties = MapSet.new(["name", "image"])
        assert MapSet.equal?(user_properties, expected_properties)
      end)
    end

    test "returns list of object properties names + id with `:id` option ", %{conn: conn} do
      rollback(conn, fn conn ->
        EdgeDB.query!(conn, """
        INSERT User {
          name := "username",
          image := "http://example.com/some/url"
        }
        """)

        user_properties =
          conn
          |> EdgeDB.query_required_single!("SELECT User { name, image } LIMIT 1")
          |> EdgeDB.Object.properties(id: true)
          |> MapSet.new()

        expected_properties = MapSet.new(["id", "name", "image"])
        assert MapSet.equal?(user_properties, expected_properties)
      end)
    end

    test "returns list of object properties names + id with `:implicit` option ", %{
      conn: conn
    } do
      rollback(conn, fn conn ->
        EdgeDB.query!(conn, """
        INSERT User {
          name := "username",
          image := "http://example.com/some/url"
        }
        """)

        user_properties =
          conn
          |> EdgeDB.query_required_single!("SELECT User { name, image } LIMIT 1")
          |> EdgeDB.Object.properties(implicit: true)
          |> MapSet.new()

        expected_properties = MapSet.new(["id", "name", "image"])
        assert MapSet.equal?(user_properties, expected_properties)
      end)
    end
  end

  describe "EdgeDB.Object.links/1" do
    test "returns list of object links names", %{conn: conn} do
      rollback(conn, fn conn ->
        EdgeDB.query!(conn, """
        WITH
          director := (
            INSERT Person {
              first_name := "Chris",
              middle_name := "Joseph",
              last_name := "Columbus",
              image := "",
            }
          ),
          actor1 := (
            first_name := "Daniel",
            middle_name := "Jacob",
            last_name := "Radcliffe",
            image := "",
          ),
          actor2 := (
            first_name := "Emma",
            middle_name := "Charlotte Duerre",
            last_name := "Watson",
            image := "",
          )
        INSERT Movie {
          title := "Harry Potter and the Philosopher's Stone",
          year := 2001,
          image := "",
          description := $$
            Late one night, Albus Dumbledore and Minerva McGonagall, professors at Hogwarts School of Witchcraft and Wizardry, along with the school's groundskeeper Rubeus Hagrid, deliver a recently orphaned infant named Harry Potter to his only remaining relatives, the Dursleys....
          $$,
          directors := director,
          actors := (
            FOR a in {(1, actor1), (2, actor2)}
            UNION (
              INSERT Person {
                first_name := a.1.first_name,
                middle_name := a.1.middle_name,
                last_name := a.1.last_name,
                image := a.1.image,
                @list_order := a.0
              }
            )
          )
        }
        """)

        movie_links =
          conn
          |> EdgeDB.query_required_single!("""
          SELECT Movie {
            title,
            directors,
            actors: {
              @list_order
            } ORDER BY @list_order,
          } LIMIT 1
          """)
          |> EdgeDB.Object.links()
          |> MapSet.new()

        expected_links = MapSet.new(["directors", "actors"])
        assert MapSet.equal?(movie_links, expected_links)
      end)
    end
  end

  describe "EdgeDB.Object.link_properties/1" do
    test "returns list of object link properties names", %{conn: conn} do
      rollback(conn, fn conn ->
        EdgeDB.query!(conn, """
        WITH
          director := (
            INSERT Person {
              first_name := "Chris",
              middle_name := "Joseph",
              last_name := "Columbus",
              image := "",
            }
          ),
          actor1 := (
            first_name := "Daniel",
            middle_name := "Jacob",
            last_name := "Radcliffe",
            image := "",
          ),
          actor2 := (
            first_name := "Emma",
            middle_name := "Charlotte Duerre",
            last_name := "Watson",
            image := "",
          )
        INSERT Movie {
          title := "Harry Potter and the Philosopher's Stone",
          year := 2001,
          image := "",
          description := $$
            Late one night, Albus Dumbledore and Minerva McGonagall, professors at Hogwarts School of Witchcraft and Wizardry, along with the school's groundskeeper Rubeus Hagrid, deliver a recently orphaned infant named Harry Potter to his only remaining relatives, the Dursleys....
          $$,
          directors := director,
          actors := (
            FOR a in {(1, actor1), (2, actor2)}
            UNION (
              INSERT Person {
                first_name := a.1.first_name,
                middle_name := a.1.middle_name,
                last_name := a.1.last_name,
                image := a.1.image,
                @list_order := a.0
              }
            )
          )
        }
        """)

        movie =
          EdgeDB.query_required_single!(conn, """
          SELECT Movie {
            title,
            directors,
            actors: {
              @list_order
            } ORDER BY @list_order,
          } LIMIT 1
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
    test "returns map converted from object", %{conn: conn} do
      object =
        EdgeDB.query_required_single!(conn, """
         SELECT schema::Property {
             name,
             annotations: {
               name,
               @value
             }
         }
         FILTER .name = 'listen_port' AND .source.name = 'cfg::Config'
         LIMIT 1
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
