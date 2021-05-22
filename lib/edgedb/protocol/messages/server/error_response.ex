defmodule EdgeDB.Protocol.Messages.Server.ErrorResponse do
  use EdgeDB.Protocol.Message

  import EdgeDB.Protocol.Types.Header

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
      attributes: [Types.Header.t()] | Keyword.t()
    ],
    known_headers: %{
      0x0001 => :hint,
      0x0002 => :details,
      0x0101 => :server_traceback,
      0xFFF1 => :position_start,
      0xFFF2 => :position_end,
      0xFFF3 => :line_start,
      0xFFF4 => :column_start,
      0xFFF5 => :utf16_column_start,
      0xFFF6 => :line_end,
      0xFFF7 => :column_end,
      0xFFF8 => :utf16_column_end,
      0xFFF9 => :character_start,
      0xFFFA => :character_end
    }
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
      attributes: process_headers(attributes)
    )
  end
end
