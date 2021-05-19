defmodule EdgeDB.Protocol.DataTypes.UInt16 do
  use EdgeDB.Protocol.DataType

  defdatatype(type: pos_integer())

  @spec encode(t()) :: bitstring()
  def encode(integer) do
    <<integer::uint16>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<integer::uint16, rest::binary>>) do
    {integer, rest}
  end
end
