defmodule EdgeDB.Protocol.DataTypes.Int16 do
  use EdgeDB.Protocol.DataType

  @int16_max 0x7FFF
  @int16_min -0x8000

  defguard is_int16(number)
           when is_integer(number) and @int16_min <= number and number <= @int16_max

  defdatatype(type: integer())

  @spec encode(t()) :: bitstring()
  def encode(number) when is_int16(number) do
    <<number::int16>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<number::int16, rest::binary>>) do
    {number, rest}
  end
end
