# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - Unreleased

[Compare with 0.1.0](https://github.com/nsidnev/edgedb-elixir/compare/v0.1.0...HEAD)

### Added

- `EdgeDB.Object.fields/2`, `EdgeDB.Object.properties/2`, `EdgeDB.Object.links/1` and `EdgeDB.Object.link_properties/1` functions to inspect the fields of the object.
- `EdgeDB.Error.inheritor?/2` function to check if the exception is an inheritor of another EdgeDB error.
- `EdgeDB.Sandbox` module for use in tests involving database modifications.

### Fixed

- creation of `EdgeDB.Object` properties equal to an empty `EdgeDB.Set`.
- access to TLS certificate from connection options.

## [0.1.0] - 2022-02-10

[Compare with first commit](https://github.com/nsidnev/edgedb-elixir/compare/a9c18f910e36e728eb8d59e6e8e41721474f201c...v0.1.0)

### Added

- First release.
