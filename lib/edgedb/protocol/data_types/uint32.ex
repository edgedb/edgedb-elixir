defmodule EdgeDB.Protocol.DataTypes.UInt32 do
  use EdgeDB.Protocol.DataType

  defdatatype(type: pos_integer())

  @spec encode(t()) :: bitstring()
  def encode(integer) do
    <<integer::uint32>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<integer::uint32, rest::binary>>) do
    {integer, rest}
  end
end
