defmodule EdgeDB.Protocol.Messages.Client.ExecuteScript do
  use EdgeDB.Protocol.Message

  import EdgeDB.Protocol.Types.Header

  alias EdgeDB.Protocol.{
    DataTypes,
    Enums,
    Types
  }

  @known_headers %{
    allow_capabilities: {0xFF04, &Enums.Capability.encode/1}
  }
  @known_headers_keys Map.keys(@known_headers)

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
    encoded_headers =
      headers
      |> process_headers()
      |> Types.Header.encode()

    [encoded_headers, DataTypes.String.encode(script)]
  end

  @spec process_headers(list(Types.Header.t())) :: list(Types.Header.t())
  defp process_headers(headers) do
    Enum.reduce(headers, [], fn
      header(code: code, value: value), headers when code in @known_headers_keys ->
        {code, encoder} = @known_headers[code]
        [header(code: code, value: encoder.(value)) | headers]

      _unknown_header, headers ->
        headers
    end)
  end
end
