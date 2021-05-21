defmodule EdgeDB.Protocol.Types.Dimension do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  @lower 1

  deftype(
    name: :dimension,
    fields: [
      upper: DataTypes.Int32.t(),
      lower: DataTypes.Int32.t()
    ],
    defaults: [
      lower: @lower
    ]
  )

  @spec encode(t()) :: iodata()
  def encode(dimension(upper: upper, lower: @lower)) do
    [
      DataTypes.Int32.encode(upper),
      DataTypes.Int32.encode(@lower)
    ]
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<upper::int32, @lower::int32, rest::binary>>) do
    {dimension(upper: upper), rest}
  end
end
