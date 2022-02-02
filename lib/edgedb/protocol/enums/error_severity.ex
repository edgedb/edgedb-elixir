defmodule EdgeDB.Protocol.Enums.ErrorSeverity do
  @moduledoc false

  use EdgeDB.Protocol.Enum

  defenum(
    values: [
      error: 0x78,
      fatal: 0xC8,
      panic: 0xFF
    ],
    guard: :is_error_severity
  )
end
