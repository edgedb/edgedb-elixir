defmodule EdgeDB.Protocol.Enums.IOFormat do
  use EdgeDB.Protocol.Enum

  defenum(
    values: [
      binary: 0x62,
      json: 0x6A,
      json_elements: 0x4A
    ]
  )
end
