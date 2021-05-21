defmodule EdgeDB.Protocol.TypeDescriptors.TupleTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    DataTypes
  }

  deftypedescriptor(type: 4)

  @spec parse_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) ::
          {Codec.t(), bitstring()}
  defp parse_description(codecs, type_id, <<element_count::uint16, rest::binary>>) do
    {element_types, rest} = DataTypes.UInt16.decode(element_count, rest)

    codecs =
      Enum.map(element_types, fn type_pos ->
        codec_by_index(codecs, type_pos)
      end)

    {Codecs.Tuple.new(type_id, codecs), rest}
  end

  @spec consume_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) :: bitstring()
  defp consume_description(_storage, _id, <<element_count::uint16, rest::binary>>) do
    {_element_types, rest} = DataTypes.UInt16.decode(element_count, rest)

    rest
  end
end
