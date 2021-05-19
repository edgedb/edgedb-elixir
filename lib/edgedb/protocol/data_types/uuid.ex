defmodule EdgeDB.Protocol.DataTypes.UUID do
  use EdgeDB.Protocol.DataType

  defdatatype(type: [byte()])

  @spec encode(t()) :: bitstring()
  def encode(uuid) do
    <<uuid::uuid>>
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<uuid::uuid, rest::binary>>) do
    {uuid, rest}
  end

  @spec from_string(binary()) :: bitstring()
  def from_string(str_uuid) do
    UUID.string_to_binary!(str_uuid)
  end

  @spec from_binary(bitstring()) :: bitstring()
  def from_binary(<<bin_uuid::uuid>>) do
    bin_uuid
  end

  @spec from_integer(integer()) :: bitstring()
  def from_integer(int_uuid) do
    <<int_uuid::uuid>>
  end

  @spec to_string(bitstring()) :: binary()
  def to_string(<<_content::uuid>> = bin_uuid) do
    UUID.binary_to_string!(bin_uuid)
  end
end
