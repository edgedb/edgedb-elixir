defmodule EdgeDB.Protocol.Enums.IOFormat do
  @moduledoc """
  Data I/O format.

  Values:

    * `:binary` - return data encoded in binary.
    * `:json` - return data as single row and single field that contains
      the result set as a single JSON array.
    * `:json_elements` - return a single JSON string per top-level set element.
      This can be used to iterate over a large result set efficiently.
  """

  use EdgeDB.Protocol.Enum

  defenum(
    values: [
      binary: 0x62,
      json: 0x6A,
      json_elements: 0x4A
    ]
  )
end
