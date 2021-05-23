defmodule EdgeDB.Protocol.Codecs.EmptyResult do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    DataTypes,
    Errors
  }

  defbasescalarcodec(
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-000000000000"),
    type: nil,
    calculate_size?: false
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(_instance) do
    raise Errors.InvalidArgumentError, "empty result can't be encoded by client"
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(_data) do
    raise Errors.InvalidArgumentError, "empty result can't be decoded by client"
  end
end
