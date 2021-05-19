defmodule EdgeDB.Protocol.TypeDescriptors.ObjectShapeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  import EdgeDB.Protocol.Types.ShapeElement

  alias EdgeDB.Protocol.{Codecs, Types}

  deftypedescriptor(type: 1)

  defp parse_description(codecs, type_id, <<elements_count::uint16, rest::binary>>) do
    {elements, rest} = Types.ShapeElement.decode(elements_count, rest)

    codecs =
      Enum.map(elements, fn shape_element(type_pos: pos) ->
        codec_by_index(codecs, pos)
      end)

    {Codecs.Object.new(type_id, elements, codecs), rest}
  end

  defp consume_description(_storage, _type_id, <<elements_count::uint16, rest::binary>>) do
    {_elements, rest} = Types.ShapeElement.decode(elements_count, rest)

    rest
  end
end
