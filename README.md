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
2. Support for pool resize and other settings through server hints (?)
3. Better public API
4. Better tests and coverage
5. Ability to configure some parts (JSON, timeouts, etc)
6. Documentation
7. Publish package
