defmodule EdgeDB.Protocol.DataTypes.UUID do
  use EdgeDB.Protocol.DataType

  defdatatype(type: bitstring())

  @spec encode(t() | String.t()) :: bitstring()

  def encode(<<_content::uuid>> = bin_uuid) do
    bin_uuid
  end

  def encode(uuid) when is_binary(uuid) do
    UUID.string_to_binary!(uuid)
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<uuid::uuid, rest::binary>>) do
    {<<uuid::uuid>>, rest}
  end

  @spec from_integer(integer()) :: bitstring()
  def from_integer(int_uuid) when is_integer(int_uuid) do
    <<int_uuid::uuid>>
  end

  @spec from_string(binary()) :: bitstring()
  def from_string(str_uuid) when is_binary(str_uuid) do
    UUID.string_to_binary!(str_uuid)
  end

  @spec to_string(bitstring()) :: binary()
  def to_string(<<_content::uuid>> = bin_uuid) do
    UUID.binary_to_string!(bin_uuid)
  end
end
