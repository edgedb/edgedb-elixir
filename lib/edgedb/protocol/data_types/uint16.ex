defmodule EdgeDB.Protocol.DataTypes.UInt16 do
  use EdgeDB.Protocol.DataType

  @uint16_max 0xFFFF
  @uint16_min 0x0

  defguard is_uint16(number)
           when is_integer(number) and @uint16_min <= number and number <= @uint16_max

  defdatatype(type: pos_integer())

  @spec encode(t()) :: bitstring()
  def encode(number) when is_uint16(number) do
    <<number::uint16>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<number::uint16, rest::binary>>) do
    {number, rest}
  end
end
