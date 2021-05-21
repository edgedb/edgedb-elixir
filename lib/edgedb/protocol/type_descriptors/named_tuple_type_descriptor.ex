defmodule EdgeDB.Protocol.TypeDescriptors.NamedTupleTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  import EdgeDB.Protocol.Types.NamedTupleDescriptorElement

  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    DataTypes,
    Types
  }

  deftypedescriptor(type: 5)

  @spec parse_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) ::
          {Codec.t(), bitstring()}
  defp parse_description(codecs, type_id, <<element_count::uint16, rest::binary>>) do
    {elements, rest} = Types.NamedTupleDescriptorElement.decode(element_count, rest)

    codecs =
      Enum.map(elements, fn named_tuple_descriptor_element(type_pos: type_pos) ->
        codec_by_index(codecs, type_pos)
      end)

    {Codecs.NamedTuple.new(type_id, elements, codecs), rest}
  end

  @spec consume_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) :: bitstring()
  defp consume_description(_storage, _id, <<element_count::uint16, rest::binary>>) do
    {_elements, rest} = Types.NamedTupleDescriptorElement.decode(element_count, rest)

    rest
  end
end
