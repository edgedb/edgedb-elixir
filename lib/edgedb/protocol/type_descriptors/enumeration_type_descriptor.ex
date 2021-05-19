defmodule EdgeDB.Protocol.TypeDescriptors.EnumerationTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{Codecs, DataTypes}

  deftypedescriptor(type: 7)

  defp parse_description(_codecs, id, <<members_count::uint16, rest::binary>>) do
    {members, rest} = DataTypes.String.decode(members_count, rest)
    {Codecs.Enum.new(id, members), rest}
  end

  defp consume_description(_storage, _id, <<members_count::uint16, rest::binary>>) do
    {_members, rest} = DataTypes.String.decode(members_count, rest)
    rest
  end
end
