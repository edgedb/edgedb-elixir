defmodule EdgeDB.Protocol.Codecs.Str do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  defbasescalarcodec(
    type_name: "std::str",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-000000000101"),
    type: binary(),
    calculate_size?: false
  )

  @spec encode_instance(t() | String.Chars.t()) :: iodata()
  def encode_instance(string) do
    DataTypes.String.encode(string)
  end

  @spec decode_instance(bitstring()) :: {t(), bitstring()}
  def decode_instance(data) do
    {string, <<>>} = DataTypes.String.decode(data)
    string
  end
end
