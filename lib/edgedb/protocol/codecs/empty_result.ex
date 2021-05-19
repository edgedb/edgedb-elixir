defmodule EdgeDB.Protocol.Codecs.EmptyResult do
  use EdgeDB.Protocol.Codec

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-000000000000"),
    type: any()
  )

  @spec encode_instance(t()) :: bitstring()
  def encode_instance(_instance) do
    raise EdgeDB.Protocol.Errors.InvalidArgumentError, "empty result can't be encoded by client"
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(_data) do
    raise EdgeDB.Protocol.Errors.InvalidArgumentError, "empty result can't be decoded by client"
  end
end
