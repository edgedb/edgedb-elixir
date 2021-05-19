defmodule EdgeDB.Protocol.Messages.Client.RestoreBlock do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  defmessage(
    client: true,
    mtype: 0x3D,
    name: :restore_block,
    fields: [
      block_data: DataTypes.Bytes.t()
    ]
  )

  @spec encode_message(t()) :: bitstring()
  defp encode_message(restore_block(block_data: block_data)) do
    [DataTypes.Bytes.encode(block_data)]
  end
end
