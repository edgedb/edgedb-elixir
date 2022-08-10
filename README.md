# Elixir client for EdgeDB

Documentation: https://hexdocs.pm/edgedb

How to use:

```elixir
iex(1)> {:ok, client} = EdgeDB.start_link() # NOTE: you should initialize EdgeDB project first
iex(2)> arg = [16, 13, 2, 42]
iex(3)> ^arg = EdgeDB.query_required_single!(client, "select <array<int64>>$arg", arg: arg)
[16, 13, 2, 42]
```

# TODO:
1. Query builder with schema reflection (long term)
