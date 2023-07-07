# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

[Compare with 0.6.1](https://github.com/edgedb/edgedb-elixir/compare/v0.6.1...HEAD)

## [0.6.1] - 2023-07-07

[Compare with 0.6.0](https://github.com/edgedb/edgedb-elixir/compare/v0.6.0...v0.6.1)

### Added

- support for `Elixir v1.15` and `Erlang/OTP 26`.

### Fixed

- encoding of `t:EdgeDB.Range.t/0` values.
- constructing `t:EdgeDB.Range.t/0` from `EdgeDB.Range.new/3` with `nil` as values.
- examples in the documentation and the `Inspect` implementation of
    `t:EdgeDB.DateDuration.t/0` and `t:EdgeDB.Range.t/0`.

## [0.6.0] - 2023-06-22

[Compare with 0.5.1](https://github.com/edgedb/edgedb-elixir/compare/v0.5.1...v0.6.0)

### Added

- support for `cal::date_duration` EdgeDB type via `EdgeDB.DateDuration` structure.
- support for EdgeDB Cloud.
- support for tuples and named tuples as query arguments.
- support for `EdgeDB 3.0`.
- support for `ext::pgvector::vector` type.

### Changed

- implementation of `Enumerable` protocol for `EdgeDB.Set`.
- `EdgeDB.State` to `EdgeDB.Client.State`, `EdgeDB.with_state/2` to
    `EdgeDB.with_client_state/2`, `:state` option to `:client_state`.
- license from `MIT` to `Apache 2.0`.

### Fixed

- crash after updating `db_connection` to `2.5`.
- decoding a single propery for `EdgeDB.Object` that equals to an empty set.
- not catching an `EdgeDB.Error` exception during parameters encoding,
    which caused throwing an exception for non-`!` functions.
- silent error for calling `EdgeDB` API with wrong module names.

### Removed

- `EdgeDB.subtransaction/2`, `EdgeDB.subtransaction!/2` functions and other mentions of
    subtransactions support in the client.
- support for custom pool configuration.
- `:raw` option from `EdgeDB.query*` functions as well as access to `EdgeDB.Query`
    and `EdgeDB.Result`.
- API for constructing an `EdgeDB.Error`.

## [0.5.1] - 2022-08-25

[Compare with 0.5.0](https://github.com/edgedb/edgedb-elixir/compare/v0.5.0...v0.5.1)

### Removed

- unintentional ping log for the connection.

## [0.5.0] - 2022-08-20

[Compare with 0.4.0](https://github.com/edgedb/edgedb-elixir/compare/v0.4.0...v0.5.0)

### Added

- `EdgeDB.Client` module that is acceptable by all `EdgeDB` API.
- `:max_concurrency` option to start pool to control max connections count in `EdgeDB.Pool`.

### Changed

- default pool from `DBConnection.Pool` to `EdgeDB.Pool`.
- `EdgeDB.Pool` to be "real" lazy and dynamic: all idle connections that EdgeDB wants to drop
    will be disconnected from the pool, new connections will be created only on user queries
    depending on EdgeDB concurrency suggest as soft limit and `:max_concurrency` option as hard limit
    of connections count.
- first parameter accepted by callbacks in `EdgeDB.transaction/3`, `EdgeDB.subtransaction/2`
    and `EdgeDB.subtransaction!/2` from `t:DBConnection.t/0` to `t:EdgeDB.Client.t/0`.
- `EdgeDB.connection/0` to `t:EdgeDB.client/0`.
- `EdgeDB.edgedb_transaction_option/0` to `t:EdgeDB.Client.transaction_option/0`.
- `EdgeDB.retry_option/0` to `t:EdgeDB.Client.retry_option/0`.
- `EdgeDB.retry_rule/0` to `t:EdgeDB.Client.retry_rule/0`.

### Fixed

- concurrent transactions when client was unintentionally marked as borrowed for transaction instead of connection.

### Removed

- `EdgeDB.WrappedConnection` module in favor of `EdgeDB.Client`.

## [0.4.0] - 2022-08-04

[Compare with 0.3.0](https://github.com/edgedb/edgedb-elixir/compare/v0.3.0...v0.4.0)

### Added

- support for `EdgeDB 2.0` with new binary protocol.
- support for EdgeQL state via `EdgeDB.State`.
- new `EdgeDB.Range` type to represent ranges from `EdgeDB 2.0`.
- support for multiple EdgeQL statements execution via `EdgeDB.execute/4` and `EdgeDB.execute!/4`.

### Changed

- `io_format` option to `output_format`.

### Fixed

- the ability to pass maps or keyword lists in a query that requires positional arguments.

## [0.3.0] - 2022-05-29

[Compare with 0.2.1](https://github.com/edgedb/edgedb-elixir/compare/v0.2.1...v0.3.0)

### Added

- maps as a valid type for query arguments.
- `EdgeDB.Object.to_map/1` and `EdgeDB.NamedTuple.to_map/1` functions.
- optional support for `std::datetime` EdgeDB type via `Timex.Duration` structure.
- custom modules for each EdgeDB exception with the `new/2` function, that will return the `EdgeDB.Error` exception.
- documentation for `EdgeDB.Error` functions that create new exceptions.

### Removed

- legacy arguments encoding.

### Changed

- `EdgeQL` queries to be lowercase.
- `EdgeDB.Error.inheritor?/2` to work with generated module names for EdgeDB exceptions instead of atoms.

## [0.2.1] - 2022-05-19

[Compare with 0.2.0](https://github.com/edgedb/edgedb-elixir/compare/v0.2.0...v0.2.1)

### Removed

- mention of `:repeatable_read` option for transaction isolation mode from `t:EdgeDB.edgedb_transaction_option/0`.

### Fixed

- codec name returned by codec for `std::str` from `std::uuid` to `str::str`.
- documentation for the custom codec example, which did not have a `EdgeDB.Protocol.Codec.decode/3` implementation and used the wrong protocol.

## [0.2.0] - 2022-05-03

[Compare with 0.1.0](https://github.com/edgedb/edgedb-elixir/compare/v0.1.0...v0.2.0)

### Added

- `EdgeDB.Object.fields/2`, `EdgeDB.Object.properties/2`, `EdgeDB.Object.links/1` and `EdgeDB.Object.link_properties/1` functions to inspect the fields of the object.
- `EdgeDB.Error.inheritor?/2` function to check if the exception is an inheritor of another EdgeDB error.
- `EdgeDB.Sandbox` module for use in tests involving database modifications.
- `EdgeDB.Pool` to support dynamic resizing of the connection pool via messages from EdgeDB server.

### Fixed

- creation of `EdgeDB.Object` properties equal to an empty `EdgeDB.Set`.
- access to TLS certificate from connection options.
- isolation configuration by dropping `REPEATABLE READ` mode, because only `SERIALIZABLE` is supported by `EdgeDB 1.0` (`REPEATABLE READ` was dropped in `EdgeDB 1.3`).
- preserving the order of the values returned when working with `EdgeDB.NamedTuple` (`EdgeDB.NamedTuple.to_tuple/1`, `EdgeDB.NamedTuple.keys/1`), including `Enumerable` protocol implementation.

### Changed

- parsing of binary data from EdgeDB by completely reworking the protocol implementation.
- internal implementation of the `Access` behaviour for `EdgeDB.Object` to improve fields access performance.

## [0.1.0] - 2022-02-10

[Compare with first commit](https://github.com/edgedb/edgedb-elixir/compare/a9c18f910e36e728eb8d59e6e8e41721474f201c...v0.1.0)

### Added

- First release.
