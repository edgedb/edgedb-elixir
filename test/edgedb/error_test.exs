defmodule Tests.ErrorTest do
  use Tests.Support.EdgeDBCase

  setup :edgedb_client

  @queries %{
    "select $0" => """
    QueryError: missing a type cast before the parameter
      ┌─ query:1:8
      │
    1 │   select $0
      │          ^^ error
    """,
    "select ('something', 42, 1 < 'kek😁lol/не англ');" => """
    InvalidTypeError: operator '<' cannot be applied to operands of type 'std::int64' and 'std::str'
      ┌─ query:1:26
      │
    1 │   select ('something', 42, 1 < 'kek😁lol/не англ');
      │                            ^^^^^^^^^^^^^^^^^^^^^^ Consider using an explicit type cast or a conversion function.
    """,
    """
    select (
        'something', 'not valid operand' < (
            2, 3, 4,
        ), 345
    );
    """ => """
    InvalidTypeError: operator '<' cannot be applied to operands of type 'std::str' and 'tuple<std::int64, std::int64, std::int64>'
      ┌─ query:2:18
      │
    2 │       'something', 'not valid operand' < (
      │ ╭──────────────────^
    3 │ │         2, 3, 4,
    4 │ │     ), 345
      │ ╰─────^ Consider using an explicit type cast or a conversion function.
    """,
    "select { x := 1 } { x := 'f̷͈͎͒̕ǫ̴̏͌ö̶̱̘' };" => """
    SchemaError: cannot redefine property 'x' of object type 'std::FreeObject' as scalar type 'std::str'
      ┌─ query:1:26
      │
    1 │   select { x := 1 } { x := 'f̷͈͎͒̕ǫ̴̏͌ö̶̱̘' };
      │                            ^^^^^ error
    """
  }

  for {query, message} <- @queries do
    message = String.trim(message)

    test "rendering error for #{inspect(query)} query", %{client: client} do
      assert {:error, %EdgeDB.Error{} = exc} = EdgeDB.query(client, unquote(query))
      assert Exception.message(exc) == unquote(message)
    end
  end
end
