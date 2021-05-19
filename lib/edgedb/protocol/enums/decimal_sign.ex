defmodule EdgeDB.Protocol.Enums.DecimalSign do
  use EdgeDB.Protocol.Enum

  defenum(
    values: [
      pos: 0x0000,
      neg: 0x4000
    ],
    data_type: EdgeDB.Protocol.DataTypes.UInt16,
    guard: :decimal_sign?
  )
end
