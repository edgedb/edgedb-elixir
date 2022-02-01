# Elixir driver for EdgeDB

How to use:
```elixir
# NOTE: you should initialize EdgeDB project first
{:ok, conn} = EdgeDB.start_link()

arg = [16, 13, 2, 42]
^arg = EdgeDB.query_single!(conn, "SELECT <array<int64>>$arg", arg: arg)
```

# TODO:
1. Support for pool resize via server hints
2. Documentation
3. Publish package
4. Query builder with schema reflection (long term)
