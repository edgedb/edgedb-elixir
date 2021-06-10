defmodule EdgeDB.Protocol.Messages.Server.ErrorResponse do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
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
      error_code: Datatypes.UInt32.t(),
      message: Datatypes.String.t(),
      attributes: Keyword.t()
    ],
    known_headers: %{
      hint: 0x0001,
      details: 0x0002,
      server_traceback: 0x0101,
      position_start: 0xFFF1,
      position_end: 0xFFF2,
      line_start: 0xFFF3,
      column_start: 0xFFF4,
      utf16_column_start: 0xFFF5,
      line_end: 0xFFF6,
      column_end: 0xFFF7,
      utf16_column_end: 0xFFF8,
      character_start: 0xFFF9,
      character_end: 0xFFFA
    }
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<severity::uint8, error_code::uint32, rest::binary>>)
      when Enums.ErrorSeverity.is_error_severity(severity) do
    {message, rest} = Datatypes.String.decode(rest)
    {num_attributes, rest} = Datatypes.UInt16.decode(rest)
    {attributes, <<>>} = Types.Header.decode(num_attributes, rest)

    error_response(
      severity: Enums.ErrorSeverity.to_atom(severity),
      error_code: error_code,
      message: message,
      attributes: process_received_headers(attributes)
    )
  end
end
