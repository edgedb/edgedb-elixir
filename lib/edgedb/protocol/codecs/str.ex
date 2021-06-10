defmodule EdgeDB.Protocol.Codecs.Str do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  defbasescalarcodec(
    type_name: "std::str",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000101"),
    type: String.t(),
    calculate_size?: false
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(string) do
    Datatypes.String.encode(string)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(data) do
    {string, <<>>} = Datatypes.String.decode(data)
    string
  end
end
