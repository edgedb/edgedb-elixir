defmodule EdgeDB.Protocol.Messages.Server.LogMessage do
  @moduledoc false

  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  require Enums.MessageSeverity

  defmessage(
    server: true,
    mtype: 0x4C,
    fields: [
      severity: Enums.MessageSeverity.t(),
      code: Datatypes.UInt32.t(),
      text: Datatypes.String.t(),
      attributes: Keyword.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<severity::uint8, code::uint32, rest::binary>>)
      when Enums.MessageSeverity.is_message_severity(severity) do
    {text, rest} = Datatypes.String.decode(rest)
    {num_attributes, rest} = Datatypes.UInt16.decode(rest)
    {attributes, <<>>} = Types.Header.decode(num_attributes, rest)

    %__MODULE__{
      severity: Enums.MessageSeverity.to_atom(severity),
      code: code,
      text: text,
      attributes: handle_headers(attributes)
    }
  end
end
