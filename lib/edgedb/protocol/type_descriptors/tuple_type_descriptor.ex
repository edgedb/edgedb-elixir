defmodule EdgeDB.Protocol.TypeDescriptors.TupleTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{DataTypes, Codecs}

  deftypedescriptor(type: 4)

  defp parse_description(codecs, type_id, <<element_count::uint16, rest::binary>>) do
    {element_types, rest} = DataTypes.UInt16.decode(element_count, rest)

    codecs =
      Enum.map(element_types, fn type_pos ->
        codec_by_index(codecs, type_pos)
      end)

    {Codecs.Tuple.new(type_id, codecs), rest}
  end

  defp consume_description(_storage, _id, <<element_count::uint16, rest::binary>>) do
    {_element_types, rest} = DataTypes.UInt16.decode(element_count, rest)

    rest
  end
end
