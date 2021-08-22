# Elixir driver for EdgeDB

How to use:
```elixir
# NOTE: you should initialize EdgeDB project first
{:ok, conn} = EdgeDB.start_link()

arg = [16, 13, 2, 42]
^arg = EdgeDB.query_single!(conn, "SELECT <array<int64>>$arg", arg: arg)
```

# TODO:
1. Support for retrying transactions and subtransactions
2. Better public API
3. Better tests and coverage
4. Ability to configure some parts (JSON, timeouts, etc)
5. Documentation
6. Publish package
