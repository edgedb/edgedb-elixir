defmodule EdgeDB.Protocol.Messages.Client.ExecuteScript do
  use EdgeDB.Protocol.Message

  import EdgeDB.Protocol.Types.Header

  alias EdgeDB.Protocol.{
    DataTypes,
    Enums,
    Types
  }

  defmessage(
    name: :execute_script,
    client: true,
    mtype: 0x51,
    fields: [
      headers: [Types.Header.t()] | Keyword.t(),
      script: DataTypes.String.t()
    ],
    known_headers: %{
      allow_capabilities: {0xFF04, &Enums.Capability.encode/1}
    }
  )

  @spec encode_message(t()) :: iodata()
  defp encode_message(execute_script(headers: headers, script: script)) do
    processed_headers = process_headers(headers)
    [Types.Header.encode(processed_headers), DataTypes.String.encode(script)]
  end
end
