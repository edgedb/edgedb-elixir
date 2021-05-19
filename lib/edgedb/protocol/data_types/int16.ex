defmodule EdgeDB.Protocol.DataTypes.Int16 do
  use EdgeDB.Protocol.DataType

  defdatatype(type: integer())

  @spec encode(t()) :: bitstring()
  def encode(integer) do
    <<integer::int16>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<integer::int16, rest::binary>>) do
    {integer, rest}
  end
end
