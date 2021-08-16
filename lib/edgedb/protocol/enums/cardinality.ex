defmodule EdgeDB.Protocol.Enums.Cardinality do
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
