defmodule EdgeDB.Protocol.Codecs.Builtin.Duration do
  @moduledoc false

  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  @days 0
  @months 0

  defbuiltinscalarcodec(
    type_name: "std::duration",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-00000000010E"),
    type: Datatypes.Int64.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(duration) when is_integer(duration) do
    [
      Datatypes.Int64.encode(duration),
      Datatypes.Int32.encode(@days),
      Datatypes.Int32.encode(@months)
    ]
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<duration::int64, @days::int32, @months::int32>>) do
    duration
  end
end
