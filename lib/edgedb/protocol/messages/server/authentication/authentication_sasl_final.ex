defmodule EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationSASLFinal do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Datatypes

  defmessage(
    server: true,
    mtype: 0x52,
    fields: [
      auth_status: 0xC,
      sasl_data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<0xC::uint32, rest::binary>>) do
    {sasl_data, <<>>} = Datatypes.Bytes.decode(rest)
    %__MODULE__{auth_status: 0xC, sasl_data: sasl_data}
  end
end
