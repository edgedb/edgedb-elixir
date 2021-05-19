defmodule EdgeDB.Protocol.Messages.Server.ReadyForCommand do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{DataTypes, Types, Enums}

  defmessage(
    server: true,
    mtype: 0x5A,
    name: :ready_for_command,
    fields: [
      headers: [Types.Header.t()],
      transaction_state: Enums.TransactionState.t()
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<value_to_decode::binary>>) do
    {num_headers, rest} = DataTypes.UInt16.decode(value_to_decode)
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {transaction_state, <<>>} = DataTypes.UInt8.decode(rest)

    ready_for_command(
      headers: headers,
      transaction_state: Enums.TransactionState.to_atom(transaction_state)
    )
  end
end
