defmodule EdgeDB.Protocol.Enums.MessageSeverity do
  @moduledoc false

  use EdgeDB.Protocol.Enum

  defenum(
    values: [
      debug: 0x14,
      info: 0x28,
      notice: 0x3C,
      warning: 0x50
    ],
    guard: :is_message_severity
  )
end
