# Elixir driver for EdgeDB

How to use (this will change to be more friendly):
```elixir
{:ok, conn} =
  EdgeDB.start_link(
    username: "edgedb",
    password: "edgedb",
    database: "edgedb",
    host: "localhost",
    port: 10_700
  )

arg = [16, 13, 2, 42]
^arg = EdgeDB.query_one!(conn, "SELECT <array<int64>>$arg", arg: arg)
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
