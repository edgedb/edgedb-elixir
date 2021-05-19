# Elixir driver for EdgeDB

How to use (this will change to be more friendly):
```elixir
{:ok, conn} =
  EdgeDB.start_link(
    username: "edgedb",
    password: "edgedb",
    database: "edgedb",
    host: "localhost",
    port: 10700
  )

query = %EdgeDB.Query{
  statement: "SELECT <array<int64>>$arg",
  io_format: :binary,
  cardinality: :one
}

arg = [16, 13, 2, 42]
{:ok, _q, r} = DBConnection.prepare_execute(conn, query, arg: arg)
^arg = EdgeDB.Result.extract(r)
```

# TODO:
1. Support for transactions
2. Public API
3. Tests
4. Code cleanup and better error handling
5. Support for SSL connections
6. Ability to configure some parts (JSON, timeouts, etc)
7. Typespecs at least for public API and dialyzer (?)
8. CI
9. Documentation
10. Publish package
