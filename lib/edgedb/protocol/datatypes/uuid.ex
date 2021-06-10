defmodule EdgeDB.Protocol.Datatypes.UUID do
  use EdgeDB.Protocol.Datatype

  defdatatype(type: bitstring())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(<<_content::uuid>> = bin_uuid) do
    bin_uuid
  end

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(uuid) when is_binary(uuid) do
    UUID.string_to_binary!(uuid)
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<uuid::uuid, rest::binary>>) do
    {<<uuid::uuid>>, rest}
  end

  @spec from_integer(integer()) :: t()
  def from_integer(int_uuid) when is_integer(int_uuid) do
    <<int_uuid::uuid>>
  end

  @spec from_string(String.t()) :: t()
  def from_string(str_uuid) when is_binary(str_uuid) do
    UUID.string_to_binary!(str_uuid)
  end

  @spec to_string(integer()) :: String.t()
  def to_string(int_uuid) when is_integer(int_uuid) do
    UUID.binary_to_string!(<<int_uuid::uuid>>)
  end

  @spec to_string(t()) :: String.t()
  def to_string(<<_content::uuid>> = bin_uuid) do
    UUID.binary_to_string!(bin_uuid)
  end
end
