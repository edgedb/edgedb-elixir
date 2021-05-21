defmodule EdgeDB.Protocol.Codecs.Str do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    calculate_size?: false,
    type_id: UUID.from_string("00000000-0000-0000-0000-000000000101"),
    type_name: "std::str",
    type: binary()
  )

  @spec encode_instance(t()) :: iodata()
  def encode_instance(string) when is_binary(string) do
    DataTypes.String.encode(string)
  end

  @spec decode_instance(bitstring()) :: {t(), bitstring()}
  def decode_instance(data) when is_bitstring(data) do
    {string, <<>>} = DataTypes.String.decode(data)
    string
  end
end
