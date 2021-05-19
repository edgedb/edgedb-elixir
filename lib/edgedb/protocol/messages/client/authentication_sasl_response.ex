defmodule EdgeDB.Protocol.Messages.Client.AuthenticationSASLResponse do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  defmessage(
    client: true,
    mtype: 0x72,
    name: :authentication_sasl_response,
    fields: [
      sasl_data: DataTypes.Bytes.t()
    ]
  )

  @spec encode_message(t()) :: bitstring()
  defp encode_message(authentication_sasl_response(sasl_data: sasl_data)) do
    [DataTypes.Bytes.encode(sasl_data)]
  end
end
