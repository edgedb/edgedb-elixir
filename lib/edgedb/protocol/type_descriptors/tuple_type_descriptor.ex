defmodule EdgeDB.Protocol.TypeDescriptors.TupleTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes
  }

  deftypedescriptor(type: 4)

  @impl EdgeDB.Protocol.TypeDescriptor
  def parse_description(codecs, type_id, <<element_count::uint16, rest::binary>>) do
    {element_types, rest} = Datatypes.UInt16.decode(element_count, rest)

    codecs =
      Enum.map(element_types, fn type_pos ->
        codec_by_index(codecs, type_pos)
      end)

    {Codecs.Builtin.Tuple.new(type_id, codecs), rest}
  end

  @impl EdgeDB.Protocol.TypeDescriptor
  def consume_description(_codecs_storage, _id, <<element_count::uint16, rest::binary>>) do
    {_element_types, rest} = Datatypes.UInt16.decode(element_count, rest)

    rest
  end
end
