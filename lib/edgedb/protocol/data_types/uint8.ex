defmodule EdgeDB.Protocol.DataTypes.UInt8 do
  use EdgeDB.Protocol.DataType

  @uint8_max 0xFF
  @uint8_min 0x0

  defguard is_uint8(number)
           when is_integer(number) and @uint8_min <= number and number <= @uint8_max

  defdatatype(type: pos_integer())

  @spec encode(t()) :: bitstring()
  def encode(number) when is_uint8(number) do
    <<number::uint8>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<number::uint8, rest::binary>>) do
    {number, rest}
  end
end
