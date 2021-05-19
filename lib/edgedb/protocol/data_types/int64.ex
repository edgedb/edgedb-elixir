defmodule EdgeDB.Protocol.DataTypes.Int64 do
  use EdgeDB.Protocol.DataType

  defdatatype(type: integer())

  @spec encode(t()) :: bitstring()
  def encode(integer) do
    <<integer::int64>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<integer::int64, rest::binary>>) do
    {integer, rest}
  end
end
