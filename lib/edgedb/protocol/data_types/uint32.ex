defmodule EdgeDB.Protocol.DataTypes.UInt32 do
  use EdgeDB.Protocol.DataType

  @uint32_max 0xFFFFFFFF
  @uint32_min 0x0

  defguard is_uint32(number)
           when is_integer(number) and @uint32_min <= number and number <= @uint32_max

  defdatatype(type: pos_integer())

  @spec encode(t()) :: bitstring()
  def encode(number) when is_uint32(number) do
    <<number::uint32>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<number::uint32, rest::binary>>) do
    {number, rest}
  end
end
