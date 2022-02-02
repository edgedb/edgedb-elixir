defmodule EdgeDB.Protocol.Enums.Cardinality do
  @moduledoc """
  Cardinality of the query result.

  Values:
    * `:no_result` - query doesn't return anything.
    * `:at_most_one` - query return an optional single elements.
    * `:one` - query return a single element.
    * `:many` - query return a set of elements.
    * `:at_least_one` - query return a set with at least of one elements.
  """

  use EdgeDB.Protocol.Enum

  defenum(
    values: [
      no_result: 0x6E,
      at_most_one: 0x6F,
      one: 0x41,
      many: 0x6D,
      at_least_one: 0x4D
    ]
  )
end
