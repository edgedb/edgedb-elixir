defmodule EdgeDB.Protocol.Messages.Server.ReadyForCommand do
  @moduledoc false

  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  defmessage(
    server: true,
    mtype: 0x5A,
    fields: [
      headers: map(),
      transaction_state: Enums.TransactionState.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<data::binary>>) do
    {num_headers, rest} = Datatypes.UInt16.decode(data)
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {transaction_state, <<>>} = Datatypes.UInt8.decode(rest)

    %__MODULE__{
      headers: handle_headers(headers),
      transaction_state: Enums.TransactionState.to_atom(transaction_state)
    }
  end
end
