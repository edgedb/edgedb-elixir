defmodule EdgeDB.Protocol.Messages.Server.LogMessage do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Enums,
    Types
  }

  require Enums.MessageSeverity

  defmessage(
    name: :log_message,
    server: true,
    mtype: 0x4C,
    fields: [
      severity: Enums.MessageSeverity.t(),
      code: DataTypes.UInt32,
      text: DataTypes.String,
      attributes: [Types.Header.t()] | Keyword.t()
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<severity::uint8, code::uint32, rest::binary>>)
       when Enums.MessageSeverity.is_message_severity(severity) do
    {text, rest} = DataTypes.String.decode(rest)
    {num_attributes, rest} = DataTypes.UInt16.decode(rest)
    {attributes, <<>>} = Types.Header.decode(num_attributes, rest)

    log_message(
      severity: Enums.MessageSeverity.to_atom(severity),
      code: code,
      text: text,
      attributes: attributes
    )
  end
end
