defmodule EdgeDB.Protocol.Messages.Client.AuthenticationSASLResponse do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Datatypes

  defmessage(
    name: :authentication_sasl_response,
    client: true,
    mtype: 0x72,
    fields: [
      sasl_data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(authentication_sasl_response(sasl_data: sasl_data)) do
    Datatypes.Bytes.encode(sasl_data)
  end
end
