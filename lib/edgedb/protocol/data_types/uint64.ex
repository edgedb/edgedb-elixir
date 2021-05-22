defmodule EdgeDB.Protocol.DataTypes.UInt64 do
  use EdgeDB.Protocol.DataType

  @uint64_max 0xFFFFFFFFFFFFFFFF
  @uint64_min 0x0

  defguard is_uint64(number)
           when is_integer(number) and @uint64_min <= number and number <= @uint64_max

  defdatatype(type: pos_integer())

  @spec encode(t()) :: bitstring()
  def encode(number) when is_uint64(number) do
    <<number::uint64>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<number::uint64, rest::binary>>) do
    {number, rest}
  end
end
