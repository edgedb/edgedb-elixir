defmodule EdgeDB.Protocol.Codecs.Builtin.Bool do
  @moduledoc false

  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  @true_code 1
  @false_code 0

  defbuiltinscalarcodec(
    type_name: "std::bool",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000109"),
    type: boolean()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(true) do
    Datatypes.Int8.encode(@true_code)
  end

  @impl EdgeDB.Protocol.Codec
  def encode_instance(false) do
    Datatypes.Int8.encode(@false_code)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<@true_code::int8>>) do
    true
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<@false_code::int8>>) do
    false
  end
end
