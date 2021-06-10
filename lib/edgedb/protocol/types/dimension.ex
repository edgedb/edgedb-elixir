defmodule EdgeDB.Protocol.Types.Dimension do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  @lower 1

  deftype(
    name: :dimension,
    fields: [
      upper: Datatypes.Int32.t(),
      lower: Datatypes.Int32.t()
    ],
    defaults: [
      lower: @lower
    ]
  )

  @impl EdgeDB.Protocol.Type
  def encode_type(dimension(upper: upper, lower: @lower)) do
    [
      Datatypes.Int32.encode(upper),
      Datatypes.Int32.encode(@lower)
    ]
  end

  @impl EdgeDB.Protocol.Type
  def decode_type(<<upper::int32, @lower::int32, rest::binary>>) do
    {dimension(upper: upper), rest}
  end
end
