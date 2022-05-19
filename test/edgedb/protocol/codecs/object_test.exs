defmodule Tests.EdgeDB.Protocol.Codecs.ObjectTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_connection

  describe "encoding object as query arguments" do
    defmodule StructForArguments do
      defstruct [:arg1, :arg2]
    end

    test "forbids using EdgeDB.Object as arguments", %{conn: conn} do
      anonymous_user =
        EdgeDB.query_required_single!(conn, """
        SELECT {
          name := "username",
          image := "http://example.com/some/url"
        }
        """)

      assert_raise EdgeDB.Error, ~r/objects encoding is not supported/, fn ->
        EdgeDB.query!(conn, "SELECT {<str>$name, <str>$image}", anonymous_user)
      end
    end

    test "forbids using custom structs as arguments", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/structs encoding is not supported/, fn ->
        EdgeDB.query!(conn, "SELECT {<str>$arg1, <str>$arg2}", %StructForArguments{
          arg1: "arg1",
          arg2: "arg2"
        })
      end
    end

    test "allows usage of plain maps as arguments", %{conn: conn} do
      assert set =
               EdgeDB.query!(conn, "SELECT {<str>$arg1, <str>$arg2}", %{
                 arg1: "arg1",
                 arg2: "arg2"
               })

      assert Enum.to_list(set) == ["arg1", "arg2"]
    end

    test "allows usage of keywords as arguments", %{conn: conn} do
      assert set =
               EdgeDB.query!(conn, "SELECT {<str>$arg1, <str>$arg2}", arg1: "arg1", arg2: "arg2")

      assert Enum.to_list(set) == ["arg1", "arg2"]
    end

    test "allows usage of plain lists as positional arguments", %{conn: conn} do
      assert set = EdgeDB.query!(conn, "SELECT {<str>$0, <str>$1}", ["arg1", "arg2"])
      assert Enum.to_list(set) == ["arg1", "arg2"]
    end

    test "allows nils for optional arguments", %{conn: conn} do
      assert is_nil(EdgeDB.query_single!(conn, "SELECT <optional str>$arg", arg: nil))
    end
  end

  describe "error for wrong query arguments" do
    test "contains expected arguments information", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/expected nothing/, fn ->
        EdgeDB.query!(conn, "SELECT 'Hello world'", arg: "Hello world")
      end

      assert_raise EdgeDB.Error, ~r/expected \["arg"\] keys/, fn ->
        EdgeDB.query!(conn, "SELECT <str>$arg")
      end
    end

    test "contains passed arguments information", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/passed \["arg"\] keys/, fn ->
        EdgeDB.query!(conn, "SELECT 'Hello world'", arg: "Hello world")
      end

      assert_raise EdgeDB.Error, ~r/passed nothing/, fn ->
        EdgeDB.query!(conn, "SELECT <str>$arg")
      end
    end

    test "contains missed arguments information", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/missed \["arg"\] keys/, fn ->
        EdgeDB.query!(conn, "SELECT <str>$arg", another_arg: "Hello world")
      end
    end

    test "contains extra arguments information", %{conn: conn} do
      assert_raise EdgeDB.Error, ~r/passed extra \["another_arg"\] keys/, fn ->
        EdgeDB.query!(conn, "SELECT <str>$arg", another_arg: "Hello world")
      end
    end
  end

  test "decoding single object", %{conn: conn} do
    rollback(conn, fn conn ->
      EdgeDB.query!(conn, """
      INSERT User {
        name := "username",
        image := "http://example.com/some/url"
      }
      """)

      user = EdgeDB.query_required_single!(conn, "SELECT User { name, image } LIMIT 1")
      assert user[:name] == "username"
      assert user[:image] == "http://example.com/some/url"
    end)
  end

  test "decoding single anonymous object", %{conn: conn} do
    rollback(conn, fn conn ->
      anonymous_user =
        EdgeDB.query_required_single!(conn, """
        SELECT {
          name := "username",
          image := "http://example.com/some/url"
        }
        """)

      assert anonymous_user[:name] == "username"
      assert anonymous_user[:image] == "http://example.com/some/url"
    end)
  end

  test "decoding object with links", %{conn: conn} do
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
        )
      INSERT Movie {
        title := "Harry Potter and the Philosopher's Stone",
        year := 2001,
        image := "",
        directors := director
      }
      """)

      movie =
        EdgeDB.query_required_single!(conn, """
        SELECT Movie {
          title,
          year,
          directors: {
            first_name,
            last_name,
          },
        } LIMIT 1
        """)

      assert movie[:title] == "Harry Potter and the Philosopher's Stone"
      assert movie[:year] == 2001

      director =
        movie[:directors]
        |> Enum.take(1)
        |> List.first()

      assert director[:first_name] == "Chris"
      assert director[:last_name] == "Columbus"
    end)
  end

  test "decoding object with links that have properties", %{conn: conn} do
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
          actors: {
            @list_order
          } ORDER BY @list_order,
        } LIMIT 1
        """)

      assert movie[:title] == "Harry Potter and the Philosopher's Stone"

      for {actor, index} <- Enum.with_index(movie[:actors], 1) do
        assert actor["@list_order"] == index
      end
    end)
  end

  test "decoding object with property equals to empty set", %{conn: conn} do
    rollback(conn, fn conn ->
      object =
        EdgeDB.query_required_single!(conn, """
        SELECT {
          a := <str>{}
        }
        LIMIT 1
        """)

      assert Enum.empty?(object[:a])
    end)
  end
end
