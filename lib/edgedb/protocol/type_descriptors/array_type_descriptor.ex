defmodule EdgeDB.Protocol.TypeDescriptors.ArrayTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    DataTypes
  }

  deftypedescriptor(type: 6)

  @spec parse_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) ::
          {Codec.t(), bitstring()}
  defp parse_description(codecs, id, <<type_pos::uint16, dimension_count::uint16, rest::binary>>) do
    {dimensions, rest} = DataTypes.Int32.decode(dimension_count, rest)
    codec = codec_by_index(codecs, type_pos)
    {Codecs.Array.new(id, dimensions, codec), rest}
  end

  @spec consume_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) :: bitstring()
  defp consume_description(
         _storage,
         _id,
         <<_type_pos::uint16, dimension_count::uint16, rest::binary>>
       ) do
    {_dimensions, rest} = DataTypes.Int32.decode(dimension_count, rest)
    rest
  end
end
