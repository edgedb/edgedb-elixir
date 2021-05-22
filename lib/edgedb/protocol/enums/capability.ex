defmodule EdgeDB.Protocol.Enums.Capability do
  use EdgeDB.Protocol.Enum

  alias EdgeDB.Protocol.DataTypes

  defenum(
    values: [
      all: 0xFFFF_FFFF_FFFF_FFFF
    ],
    data_type: DataTypes.UInt64
  )
end
