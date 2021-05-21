defmodule EdgeDB.Protocol.Messages.Client.ClientHandshake do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defmessage(
    name: :client_handshake,
    client: true,
    mtype: 0x56,
    fields: [
      params: [Types.ConnectionParam.t()],
      extensions: [Types.ProtocolExtension.t()]
    ]
  )

  @major_ver 1
  @minor_ver 0

  @spec major_ver() :: integer()
  def major_ver do
    @major_ver
  end

  @spec minor_ver() :: integer()
  def minor_ver do
    @minor_ver
  end

  @spec encode_message(t()) :: iodata()
  defp encode_message(client_handshake(params: params, extensions: extensions)) do
    [
      DataTypes.UInt16.encode(@major_ver),
      DataTypes.UInt16.encode(@minor_ver),
      Types.ConnectionParam.encode(params),
      Types.ProtocolExtension.encode(extensions)
    ]
  end
end
