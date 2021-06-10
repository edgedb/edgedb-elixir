defmodule EdgeDB.Protocol.Codecs.EmptyResult do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Datatypes,
    Errors
  }

  defbasescalarcodec(
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000000"),
    type: nil,
    calculate_size?: false
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(_instance) do
    raise Errors.InvalidArgumentError, "empty result can't be encoded by client"
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(_data) do
    raise Errors.InvalidArgumentError, "empty result can't be decoded by client"
  end
end
