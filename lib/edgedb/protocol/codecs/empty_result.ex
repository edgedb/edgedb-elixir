defmodule EdgeDB.Protocol.Codecs.EmptyResult do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Datatypes,
    Error
  }

  defbuiltinscalarcodec(
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000000"),
    type: nil,
    calculate_size: false
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(_instance) do
    raise Error.invalid_argument_error("empty result can't be encoded by client")
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(_data) do
    raise Error.invalid_argument_error("empty result can't be decoded by client")
  end
end
