defmodule EdgeDB.Protocol.Messages.Server.ReadyForCommand do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  defmessage(
    name: :ready_for_command,
    server: true,
    mtype: 0x5A,
    fields: [
      headers: Keyword.t(),
      transaction_state: Enums.TransactionState.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<data::binary>>) do
    {num_headers, rest} = Datatypes.UInt16.decode(data)
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {transaction_state, <<>>} = Datatypes.UInt8.decode(rest)

    ready_for_command(
      headers: process_received_headers(headers),
      transaction_state: Enums.TransactionState.to_atom(transaction_state)
    )
  end
end
