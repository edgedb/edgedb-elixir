defmodule EdgeDB.Protocol.Messages.Client.ClientHandshake do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{DataTypes, Types}

  defmessage(
    client: true,
    mtype: 0x56,
    name: :client_handshake,
    fields: [
      params: [Types.ConnectionParam.t()],
      extensions: [Types.ProtocolExtension.t()]
    ]
  )

  @major_ver 0
  @minor_ver 8

  @spec major_ver() :: integer()
  def major_ver, do: @major_ver

  @spec minor_ver() :: integer()
  def minor_ver, do: @minor_ver

  @spec encode_message(t()) :: bitstring()
  defp encode_message(client_handshake(params: params, extensions: extensions)) do
    [
      DataTypes.UInt16.encode(@major_ver),
      DataTypes.UInt16.encode(@minor_ver),
      Types.ConnectionParam.encode(params),
      Types.ProtocolExtension.encode(extensions)
    ]
  end
end
