defmodule EdgeDB.Protocol.DataTypes.Int64 do
  use EdgeDB.Protocol.DataType

  @int64_max 0x7FFFFFFFFFFFFFFF
  @int64_min -0x8000000000000000

  defguard is_int64(number)
           when is_integer(number) and @int64_min <= number and number <= @int64_max

  defdatatype(type: integer())

  @spec encode(t()) :: bitstring()
  def encode(number) when is_int64(number) do
    <<number::int64>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<number::int64, rest::binary>>) do
    {number, rest}
  end
end
