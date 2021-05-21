defmodule EdgeDB.Protocol.Messages.Client.AuthenticationSASLResponse do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  defmessage(
    name: :authentication_sasl_response,
    client: true,
    mtype: 0x72,
    fields: [
      sasl_data: DataTypes.Bytes.t()
    ]
  )

  @spec encode_message(t()) :: iodata()
  defp encode_message(authentication_sasl_response(sasl_data: sasl_data)) do
    [DataTypes.Bytes.encode(sasl_data)]
  end
end
