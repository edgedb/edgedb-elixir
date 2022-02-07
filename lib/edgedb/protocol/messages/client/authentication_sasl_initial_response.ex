defmodule EdgeDB.Protocol.Messages.Client.AuthenticationSASLInitialResponse do
  @moduledoc false

  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Datatypes

  defmessage(
    client: true,
    mtype: 0x70,
    fields: [
      method: Datatypes.String.t(),
      sasl_data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(%__MODULE__{method: method, sasl_data: sasl_data}) do
    [
      Datatypes.String.encode(method),
      Datatypes.Bytes.encode(sasl_data)
    ]
  end
end
