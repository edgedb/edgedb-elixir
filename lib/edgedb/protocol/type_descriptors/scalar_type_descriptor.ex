defmodule EdgeDB.Protocol.TypeDescriptors.ScalarTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    DataTypes
  }

  deftypedescriptor(type: 3)

  @spec parse_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) ::
          {Codec.t(), bitstring()}
  defp parse_description(codecs, type_id, <<type_pos::uint16, rest::binary>>) do
    codec = codec_by_index(codecs, type_pos)
    {Codecs.Scalar.new(type_id, codec), rest}
  end

  @spec consume_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) :: bitstring()
  defp consume_description(_storage, _id, <<_type_pos::uint16, rest::binary>>) do
    rest
  end
end
