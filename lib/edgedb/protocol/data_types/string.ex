defmodule EdgeDB.Protocol.DataTypes.String do
  use EdgeDB.Protocol.DataType

  defdatatype(type: String.t())

  @spec encode(t()) :: bitstring()
  def encode(string) do
    [<<byte_size(string)::uint32>>, <<string::binary>>]
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<string_size::uint32, string::binary(string_size), rest::binary>>) do
    {string, rest}
  end
end
