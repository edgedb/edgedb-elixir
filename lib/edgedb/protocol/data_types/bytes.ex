defmodule EdgeDB.Protocol.DataTypes.Bytes do
  use EdgeDB.Protocol.DataType

  defdatatype(type: bitstring())

  @spec encode(t()) :: bitstring()
  def encode(bytes) when is_bitstring(bytes) do
    [<<byte_size(bytes)::uint32>>, <<bytes::binary>>]
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<bytes_size::uint32, bytes::binary(bytes_size), rest::binary>>) do
    {bytes, rest}
  end
end
