# EdgeDB client for Elixir

`edgedb-elixir` is the [EdgeDB](https://edgedb.com) client for Elixir. The documentation for client
  is available on [edgedb.com](https://www.edgedb.com/docs/clients/elixir) and on
  [hex.pm](https://hexdocs.pm/edgedb).

## Installation

`edgedb-elixir` is available on [hex.pm](https://hex.pm/packages/edgedb) and can be installed via `mix`.
  Just add `:edgedb` to your dependencies in the `mix.exs` file:

```elixir
{:edgedb, "~> 0.1"}
```

## JSON support

`EdgeDB` comes with JSON support out of the box via the `Jason` library.
  To use it, add `:jason` to your dependencies in the `mix.exs` file:

```elixir
{:jason, "~> 1.0"}
```

The JSON library can be configured using the `:json` option in the `:edgedb` application configuration:

```elixir
config :edgedb,
    json: CustomJSONLibrary
```

The JSON library is injected in the compiled `EdgeDB` code, so be sure to recompile `EdgeDB` if you change it:

```bash
$ mix deps.clean edgedb --build
```

## Timex support

`EdgeDB` can work with `Timex` out of the box. If you define `Timex` as an application dependency,
  `EdgeDB` will use `Timex.Duration` to encode and decode the `std::duration` type from database.
  If you don't like this behavior, you can set `EdgeDB` to ignore `Timex` using
  the `:timex_duration` option by setting this to false in the `:edgedb` application configuration:

```elixir
config :edgedb,
    timex_duration: false
```

`EdgeDB` will inject the use of `Timex` into the `std::duration` codec at compile time,
  so be sure to recompile `EdgeDB` if you change this behavior:

```bash
$ mix deps.clean edgedb --build
```

## License

This project is licensed under the terms of the Apache 2.0 license.
  See [LICENSE](https://github.com/edgedb/edgedb-elixir/blob/master/LICENSE) for details.
