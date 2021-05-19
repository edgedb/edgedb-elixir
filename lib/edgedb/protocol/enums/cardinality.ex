defmodule EdgeDB.Protocol.Enums.Cardinality do
  use EdgeDB.Protocol.Enum

  defenum(
    values: [
      no_result: 0x6E,
      one: 0x6F,
      many: 0x6D
    ]
  )
end
