defmodule EdgeDB.Protocol.Codecs.UUID do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-000000000100"),
    type_name: "std::uuid",
    type: binary() | integer()
  )

  @spec encode_instance(t()) :: bitstring()

  def encode_instance(int_uuid) when is_integer(int_uuid) do
    int_uuid
    |> UUID.from_integer()
    |> DataTypes.UUID.encode()
  end

  def encode_instance(bin_uuid) when is_binary(bin_uuid) do
    bin_uuid
    |> UUID.from_binary()
    |> DataTypes.UUID.encode()
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<_content::uuid>> = bin_uuid) do
    UUID.to_string(bin_uuid)
  end
end
