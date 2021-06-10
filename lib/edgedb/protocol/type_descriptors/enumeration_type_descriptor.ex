defmodule EdgeDB.Protocol.TypeDescriptors.EnumerationTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes
  }

  deftypedescriptor(type: 7)

  @impl EdgeDB.Protocol.TypeDescriptor
  def parse_description(_codecs, id, <<members_count::uint16, rest::binary>>) do
    {members, rest} = Datatypes.String.decode(members_count, rest)
    {Codecs.Enum.new(id, members), rest}
  end

  @impl EdgeDB.Protocol.TypeDescriptor
  def consume_description(_storage, _id, <<members_count::uint16, rest::binary>>) do
    {_members, rest} = Datatypes.String.decode(members_count, rest)
    rest
  end
end
