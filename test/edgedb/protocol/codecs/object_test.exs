defmodule Tests.EdgeDB.Protocol.Codecs.ObjectTest do
  use EdgeDB.Case

  setup :edgedb_connection

  @query """
    SELECT (
      INSERT Movie {
        title := "Harry Potter and the Philosopher's Stone",
        year := 2001,
        image := "",
        description := $$
          Late one night, Albus Dumbledore and Minerva McGonagall, professors at Hogwarts School of Witchcraft and Wizardry, along with the school's groundskeeper Rubeus Hagrid, deliver a recently orphaned infant named Harry Potter to his only remaining relatives, the Dursleys....
        $$,
        directors := (
          INSERT Person {
            first_name := "Chris",
            middle_name := "Joseph",
            last_name := "Columbus",
            image := "",
          }
        ),
        actors := {
          (
            INSERT Person {
              first_name := "Daniel",
              middle_name := "Jacob",
              last_name := "Radcliffe",
              image := "",
            }
          ),
          (
            INSERT Person {
              first_name := "Emma",
              middle_name := "Charlotte Duerre",
              last_name := "Watson",
              image := "",
            }
          ),
        }
      }
    ) {
      title,
      year,
      directors: {
        first_name,
        last_name,
      },
      actors: {
        id,
        first_name,
        middle_name,
        last_name,
      }
    }
  """

  test "decoding object value", %{conn: conn} do
    assert {:error, "no need to save"} =
             EdgeDB.transaction(conn, fn conn ->
               object = EdgeDB.query_one!(conn, @query)
               assert object[:title] == "Harry Potter and the Philosopher's Stone"
               assert object[:year] == 2001

               assert [director] = Enum.take(object[:directors], 1)
               assert director[:first_name] == "Chris"
               assert director[:last_name] == "Columbus"

               assert actors = object[:actors]

               for actor <- actors do
                 assert actor[:first_name] in ["Daniel", "Emma"]
                 assert actor[:middle_name] in ["Jacob", "Charlotte Duerre"]
                 assert actor[:last_name] in ["Radcliffe", "Watson"]
               end

               EdgeDB.rollback(conn, "no need to save")
             end)
  end
end
