defmodule EdgeDB.Protocol.Messages.Server.LogMessage do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defmessage(
    name: :log_message,
    server: true,
    mtype: 0x4C,
    fields: [
      code: DataTypes.UInt32,
      text: DataTypes.String,
      attributes: [Types.Header]
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<code::uint32, rest::binary>>) do
    {text, rest} = DataTypes.String.decode(rest)
    {num_attributes, rest} = DataTypes.UInt16.decode(rest)
    {attributes, <<>>} = Types.Header.decode(num_attributes, rest)
    log_message(code: code, text: text, attributes: attributes)
  end
end
