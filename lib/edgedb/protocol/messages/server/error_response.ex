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
      hint: [
        code: 0x0001
      ],
      details: [
        code: 0x0002
      ],
      server_traceback: [
        code: 0x0101
      ],
      position_start: [
        code: 0xFFF1
      ],
      position_end: [
        code: 0xFFF2
      ],
      line_start: [
        code: 0xFFF3
      ],
      column_start: [
        code: 0xFFF4
      ],
      utf16_column_start: [
        code: 0xFFF5
      ],
      line_end: [
        code: 0xFFF6
      ],
      column_end: [
        code: 0xFFF7
      ],
      utf16_column_end: [
        code: 0xFFF8
      ],
      character_start: [
        code: 0xFFF9
      ],
      character_end: [
        code: 0xFFFA
      ]
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
      attributes: handle_headers(attributes)
    )
  end
end
