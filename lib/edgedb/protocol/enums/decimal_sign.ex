defmodule EdgeDB.Protocol.Enums.DecimalSign do
  use EdgeDB.Protocol.Enum

  alias EdgeDB.Protocol.DataTypes

  defenum(
    values: [
      pos: 0x0000,
      neg: 0x4000
    ],
    data_type: DataTypes.UInt16,
    guard: :is_decimal_sign
  )
end
