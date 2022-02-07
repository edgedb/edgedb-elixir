# Elixir driver for EdgeDB

Documentation: https://hexdocs.pm/edgedb

How to use:

```elixir
iex(1)> {:ok, conn} = EdgeDB.start_link() # NOTE: you should initialize EdgeDB project first
iex(2)> arg = [16, 13, 2, 42]
[16, 13, 2, 42]
iex(3)> ^arg = EdgeDB.query_required_single!(conn, "SELECT <array<int64>>$arg", arg: arg)
[16, 13, 2, 42]
```

# TODO:
1. Support for lazy pool with automatic resize via server hints
2. Query builder with schema reflection (long term)
