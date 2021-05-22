defmodule EdgeDB.Protocol.Codecs.UUID do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    DataTypes,
    Errors
  }

  defbasescalarcodec(
    type_name: "std::uuid",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-000000000100"),
    type: binary()
  )

  @spec encode_instance(t()) :: bitstring()

  def encode_instance(uuid) do
    DataTypes.UUID.encode(uuid)
  rescue
    _exc in ArgumentError ->
      reraise Errors.InvalidArgumentError,
              "unable to encode #{inspect(uuid)} as #{@type_name}",
              __STACKTRACE__
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<_content::uuid>> = data) do
    DataTypes.UUID.to_string(data)
  end
end
