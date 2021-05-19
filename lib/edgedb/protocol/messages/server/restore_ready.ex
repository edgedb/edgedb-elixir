defmodule EdgeDB.Protocol.Messages.Server.RestoreReady do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{DataTypes, Types}

  defmessage(
    server: true,
    mtype: 0x2B,
    name: :restore_ready,
    fields: [
      headers: [Types.Header.t()],
      jobs: DataTypes.UInt16.t()
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {jobs, <<>>} = DataTypes.UInt16.decode(rest)
    restore_ready(headers: headers, jobs: jobs)
  end
end
