defmodule EdgeDB.Protocol.Messages.Client.AuthenticationSASLInitialResponse do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  defmessage(
    name: :authentication_sasl_initial_response,
    client: true,
    mtype: 0x70,
    fields: [
      method: DataTypes.String.t(),
      sasl_data: DataTypes.Bytes.t()
    ]
  )

  @spec encode_message(t()) :: iodata()
  defp encode_message(authentication_sasl_initial_response(method: method, sasl_data: sasl_data)) do
    [
      DataTypes.String.encode(method),
      DataTypes.Bytes.encode(sasl_data)
    ]
  end
end
