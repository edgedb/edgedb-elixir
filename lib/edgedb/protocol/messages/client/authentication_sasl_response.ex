defmodule EdgeDB.Protocol.Messages.Client.AuthenticationSASLResponse do
  @moduledoc false

  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Datatypes

  defmessage(
    client: true,
    mtype: 0x72,
    fields: [
      sasl_data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(%__MODULE__{sasl_data: sasl_data}) do
    Datatypes.Bytes.encode(sasl_data)
  end
end
