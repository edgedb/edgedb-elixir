defmodule EdgeDB.Protocol.Enums.DecimalSign do
  @moduledoc false

  use EdgeDB.Protocol.Enum

  alias EdgeDB.Protocol.Datatypes

  defenum(
    values: [
      pos: 0x0000,
      neg: 0x4000
    ],
    datatype: Datatypes.UInt16,
    guard: :is_decimal_sign
  )
end
