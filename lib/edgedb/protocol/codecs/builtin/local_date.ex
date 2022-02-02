defmodule EdgeDB.Protocol.Codecs.Builtin.LocalDate do
  @moduledoc false

  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  @base_date elem(Date.new(2000, 1, 1), 1)

  defbuiltinscalarcodec(
    type_name: "cal::local_date",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-00000000010C"),
    type: Date.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(%Date{} = d) do
    days =
      @base_date
      |> Date.diff(d)
      |> abs()

    Datatypes.Int32.encode(days)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<days::int32>>) do
    Date.add(@base_date, days)
  end
end
