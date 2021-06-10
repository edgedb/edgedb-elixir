defmodule EdgeDB.Protocol.TypeDescriptors.ArrayTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes
  }

  deftypedescriptor(type: 6)

  @impl EdgeDB.Protocol.TypeDescriptor
  def parse_description(codecs, id, <<type_pos::uint16, dimension_count::uint16, rest::binary>>) do
    {dimensions, rest} = Datatypes.Int32.decode(dimension_count, rest)
    codec = codec_by_index(codecs, type_pos)
    {Codecs.Array.new(id, dimensions, codec), rest}
  end

  @impl EdgeDB.Protocol.TypeDescriptor
  def consume_description(
        _storage,
        _id,
        <<_type_pos::uint16, dimension_count::uint16, rest::binary>>
      ) do
    {_dimensions, rest} = Datatypes.Int32.decode(dimension_count, rest)
    rest
  end
end
