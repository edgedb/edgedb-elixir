defmodule EdgeDB.Protocol.DataTypes.Int32 do
  use EdgeDB.Protocol.DataType

  defdatatype(type: integer())

  @spec encode(t()) :: bitstring()
  def encode(integer) do
    <<integer::int32>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<integer::int32, rest::binary>>) do
    {integer, rest}
  end
end
