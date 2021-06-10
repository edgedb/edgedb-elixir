defmodule EdgeDB.Protocol.Messages.Client.RestoreBlock do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Datatypes

  defmessage(
    name: :restore_block,
    client: true,
    mtype: 0x3D,
    fields: [
      block_data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(restore_block(block_data: block_data)) do
    [Datatypes.Bytes.encode(block_data)]
  end
end
