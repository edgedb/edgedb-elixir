# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

[Compare with 0.3.0](https://github.com/nsidnev/edgedb-elixir/compare/v0.3.0...HEAD)

### Added

- support for `EdgeDB 2.0` with new binary protocol.
- new `EdgeDB.Range` type to represent ranges from `EdgeDB 2.0`.

### Changed

- `io_format` option to `output_format`.

### Fixed

- the ability to pass maps or keyword lists in a query that requires positional arguments.

## [0.3.0] - 2022-05-29

[Compare with 0.2.1](https://github.com/nsidnev/edgedb-elixir/compare/v0.2.1...v0.3.0)

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

[Compare with 0.2.0](https://github.com/nsidnev/edgedb-elixir/compare/v0.2.0...v0.2.1)

### Removed

- mention of `:repeatable_read` option for transaction isolation mode from `t:EdgeDB.edgedb_transaction_option/0`.

### Fixed

- codec name returned by codec for `std::str` from `std::uuid` to `str::str`.
- documentation for the custom codec example, which did not have a `EdgeDB.Protocol.Codec.decode/3` implementation and used the wrong protocol.

## [0.2.0] - 2022-05-03

[Compare with 0.1.0](https://github.com/nsidnev/edgedb-elixir/compare/v0.1.0...v0.2.0)

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

[Compare with first commit](https://github.com/nsidnev/edgedb-elixir/compare/a9c18f910e36e728eb8d59e6e8e41721474f201c...v0.1.0)

### Added

- First release.
