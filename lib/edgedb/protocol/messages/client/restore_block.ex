defmodule EdgeDB.Protocol.Messages.Client.RestoreBlock do
  @moduledoc false

  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Datatypes

  defmessage(
    client: true,
    mtype: 0x3D,
    fields: [
      block_data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(%__MODULE__{block_data: block_data}) do
    [Datatypes.Bytes.encode(block_data)]
  end
end
