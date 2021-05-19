defmodule EdgeDB.Protocol.DataTypes.UInt64 do
  use EdgeDB.Protocol.DataType

  defdatatype(type: pos_integer())

  @spec encode(t()) :: bitstring()
  def encode(integer) do
    <<integer::uint64>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<integer::uint64, rest::binary>>) do
    {integer, rest}
  end
end
