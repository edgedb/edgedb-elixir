defmodule EdgeDB.Protocol.Codecs.Builtin.Int64 do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  defbuiltinscalarcodec(
    type_name: "std::int64",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000105"),
    type: Datatypes.Int64.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(number) do
    Datatypes.Int64.encode(number)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<number::int64>>) do
    number
  end
end
