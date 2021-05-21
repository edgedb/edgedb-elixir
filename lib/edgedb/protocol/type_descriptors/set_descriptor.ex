defmodule EdgeDB.Protocol.TypeDescriptors.SetDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    DataTypes
  }

  deftypedescriptor(type: 0)

  @spec parse_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) ::
          {Codec.t(), bitstring()}
  defp parse_description(codecs, id, <<type_pos::uint16, rest::binary>>) do
    codec = codec_by_index(codecs, type_pos)
    {Codecs.Set.new(id, codec), rest}
  end

  @spec consume_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) :: bitstring()
  defp consume_description(_storage, _id, <<_type_pos::uint16, rest::binary>>) do
    rest
  end
end
