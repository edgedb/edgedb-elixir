defmodule EdgeDB.Protocol.Messages.Client.RestoreBlock do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.DataTypes

  defmessage(
    name: :restore_block,
    client: true,
    mtype: 0x3D,
    fields: [
      block_data: DataTypes.Bytes.t()
    ]
  )

  @spec encode_message(t()) :: iodata()
  defp encode_message(restore_block(block_data: block_data)) do
    [DataTypes.Bytes.encode(block_data)]
  end
end
