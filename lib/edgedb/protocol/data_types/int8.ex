defmodule EdgeDB.Protocol.DataTypes.Int8 do
  use EdgeDB.Protocol.DataType

  defdatatype(type: integer())

  @spec encode(t()) :: bitstring()
  def encode(integer) do
    <<integer::int8>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<integer::int8, rest::binary>>) do
    {integer, rest}
  end
end
