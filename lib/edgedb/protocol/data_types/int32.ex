defmodule EdgeDB.Protocol.DataTypes.Int32 do
  use EdgeDB.Protocol.DataType

  @int32_max 0x7FFFFFFF
  @int32_min -0x80000000

  defguard is_int32(number)
           when is_integer(number) and @int32_min <= number and number <= @int32_max

  defdatatype(type: integer())

  @spec encode(t()) :: bitstring()
  def encode(number) when is_int32(number) do
    <<number::int32>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<number::int32, rest::binary>>) do
    {number, rest}
  end
end
