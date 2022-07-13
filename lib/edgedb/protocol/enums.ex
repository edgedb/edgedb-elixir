defmodule EdgeDB.Protocol.Enums do
  @moduledoc since: "0.2.0"
  @moduledoc """
  Definition for enumerations used in EdgeDB protocol.
  """

  @typedoc """
  Query capabilities.

  Values:

    * `:readonly` - query is read-only.
    * `:modifications` - query is not read-only.
    * `:session_config` - query contains session config change.
    * `:transaction` - query contains start/commit/rollback of transaction or savepoint manipulation.
    * `:ddl` - query contains DDL.
    * `:persistent_config` - server or database config change.
    * `:all` - all possible capabilities.
    * `:execute` - capabilities to execute query.
  """
  @type capability() ::
          :readonly
          | :modifications
          | :session_config
          | :transaction
          | :ddl
          | :persistent_config
          | :all
          | :execute

  @typedoc """
  Query capabilities.
  """
  @type capabilities() :: list(capability())

  @typedoc """
  Compilation flags for query to extend it's features.

  Values:

    * `:inject_output_type_ids` - inject `__tid__` property as `.__type__.id` alias into returned objects.
    * `:inject_output_type_names` - inject `__tname__` property as `.__type__.name` alias into returned objects.
    * `:inject_output_object_ids` - inject `id` property into returned objects.
  """
  @type compilation_flag() ::
          :inject_output_type_ids
          | :inject_output_type_names
          | :inject_output_object_ids

  @typedoc """
  Compilation flags for query to extend it's features.
  """
  @type compilation_flags() :: list(compilation_flag())

  @typedoc false
  @type transaction_state() ::
          :not_in_transaction
          | :in_transaction
          | :in_failed_transcation

  @typedoc """
  Data output format.

  Values:

    * `:binary` - return data encoded in binary.
    * `:json` - return data as single row and single field that contains
      the result set as a single JSON array.
    * `:json_elements` - return a single JSON string per top-level set element.
      This can be used to iterate over a large result set efficiently.
    * `:none` - prevent EdgeDB from returning anything event if EdgeQL query does it.
  """
  @type output_format() ::
          :binary
          | :json
          | :json_elements
          | :none

  @typedoc """
  Cardinality of the query result.

  Values:

    * `:no_result` - query doesn't return anything.
    * `:at_most_one` - query return an optional single elements.
    * `:one` - query return a single element.
    * `:many` - query return a set of elements.
    * `:at_least_one` - query return a set with at least of one elements.
  """
  @type cardinality() ::
          :no_result
          | :at_most_one
          | :one
          | :many
          | :at_least_one

  @typedoc false
  @type describe_aspect() ::
          :data_description

  @typedoc false
  @type error_severity() ::
          :error
          | :fatal
          | :panic

  @typedoc false
  @type message_severity() ::
          :debug
          | :info
          | :notice
          | :warning
end
