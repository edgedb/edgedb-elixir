defmodule EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationSASLContinue do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  defmessage(
    server: true,
    mtype: 0x52,
    name: :authentication_sasl_continue,
    fields: [
      auth_status: 0xB,
      sasl_data: DataTypes.Bytes.t()
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<0xB::uint32, rest::binary>>) do
    {sasl_data, <<>>} = DataTypes.Bytes.decode(rest)
    authentication_sasl_continue(auth_status: 0xB, sasl_data: sasl_data)
  end
end
