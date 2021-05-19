defmodule EdgeDB.Protocol.Enums.ErrorSeverity do
  use EdgeDB.Protocol.Enum

  defenum(
    values: [
      error: 0x78,
      fatal: 0xC8,
      panic: 0xFF
    ],
    guard: :error_severity?
  )
end
