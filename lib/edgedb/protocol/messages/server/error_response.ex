defmodule EdgeDB.Protocol.Messages.Server.ErrorResponse do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Enums,
    Types
  }

  require Enums.ErrorSeverity

  defmessage(
    name: :error_response,
    server: true,
    mtype: 0x45,
    fields: [
      severity: Enums.ErrorSeverity.t(),
      error_code: DataTypes.UInt32.t(),
      message: DataTypes.String.t(),
      attributes: [Types.Header.t()]
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<severity::uint8, error_code::uint32, rest::binary>>)
       when Enums.ErrorSeverity.is_error_severity(severity) do
    {message, rest} = DataTypes.String.decode(rest)
    {num_attributes, rest} = DataTypes.UInt16.decode(rest)
    {attributes, <<>>} = Types.Header.decode(num_attributes, rest)

    error_response(
      severity: Enums.ErrorSeverity.to_atom(severity),
      error_code: error_code,
      message: message,
      attributes: attributes
    )
  end
end
