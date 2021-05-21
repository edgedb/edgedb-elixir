defmodule EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationSASL do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  defmessage(
    name: :authentication_sasl,
    server: true,
    mtype: 0x52,
    fields: [
      auth_status: 0xA,
      methods: [DataTypes.String.t()]
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<0xA::uint32, num_methods::uint32, rest::binary>>) do
    {methods, <<>>} = DataTypes.String.decode(num_methods, rest)
    authentication_sasl(auth_status: 0xA, methods: methods)
  end
end
