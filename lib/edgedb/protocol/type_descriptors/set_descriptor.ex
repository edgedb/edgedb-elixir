defmodule EdgeDB.Protocol.TypeDescriptors.SetDescriptor do
  @moduledoc false

  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.Codecs

  deftypedescriptor(type: 0)

  @impl EdgeDB.Protocol.TypeDescriptor
  def parse_description(codecs, id, <<type_pos::uint16, rest::binary>>) do
    codec = codec_by_index(codecs, type_pos)
    {Codecs.Builtin.Set.new(id, codec), rest}
  end

  @impl EdgeDB.Protocol.TypeDescriptor
  def consume_description(_codecs_storage, _id, <<_type_pos::uint16, rest::binary>>) do
    rest
  end
end
