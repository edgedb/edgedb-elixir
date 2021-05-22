defmodule EdgeDB.Protocol.DataTypes.Int8 do
  use EdgeDB.Protocol.DataType

  @int8_max 0x7F
  @int8_min -0x80

  defguard is_int8(number)
           when is_integer(number) and @int8_min <= number and number <= @int8_max

  defdatatype(type: integer())

  @spec encode(t()) :: bitstring()
  def encode(number) when is_int8(number) do
    <<number::int8>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<number::int8, rest::binary>>) do
    {number, rest}
  end
end
