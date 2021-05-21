defmodule EdgeDB.Protocol.Messages.Client.ExecuteScript do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defmessage(
    name: :execute_script,
    client: true,
    mtype: 0x51,
    fields: [
      headers: [Types.Header.t()],
      script: DataTypes.String.t()
    ]
  )

  @spec encode_message(t()) :: iodata()
  defp encode_message(execute_script(headers: headers, script: script)) do
    [Types.Header.encode(headers), DataTypes.String.encode(script)]
  end
end
