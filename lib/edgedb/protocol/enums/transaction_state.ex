defmodule EdgeDB.Protocol.Enums.TransactionState do
  use EdgeDB.Protocol.Enum

  defenum(
    values: [
      not_in_transaction: 0x49,
      in_transaction: 0x54,
      in_failed_transaction: 0x45
    ]
  )
end
