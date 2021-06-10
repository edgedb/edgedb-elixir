defmodule EdgeDB.Protocol.Enums.Capability do
  use EdgeDB.Protocol.Enum

  alias EdgeDB.Protocol.Datatypes

  defenum(
    values: [
      readonly: 0x0,
      modifications: 0x1,
      session_config: 0x2,
      transactions: 0x4,
      ddl: 0x8,
      persistent_config: 0x10,
      all: 0xFFFF_FFFF_FFFF_FFFF,
      execute: 0xFFFF_FFFF_FFFF_FFFB
    ],
    datatype: Datatypes.UInt64
  )
end
