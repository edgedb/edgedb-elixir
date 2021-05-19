defmodule EdgeDB.Protocol.DataTypes.UInt8 do
  use EdgeDB.Protocol.DataType

  defdatatype(type: pos_integer())

  @spec encode(t()) :: bitstring()
  def encode(integer) do
    <<integer::uint8>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<integer::uint8, rest::binary>>) do
    {integer, rest}
  end
end
