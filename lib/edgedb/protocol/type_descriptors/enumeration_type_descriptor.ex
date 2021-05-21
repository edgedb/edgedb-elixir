defmodule EdgeDB.Protocol.TypeDescriptors.EnumerationTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    DataTypes
  }

  deftypedescriptor(type: 7)

  @spec parse_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) ::
          {Codec.t(), bitstring()}
  defp parse_description(_codecs, id, <<members_count::uint16, rest::binary>>) do
    {members, rest} = DataTypes.String.decode(members_count, rest)
    {Codecs.Enum.new(id, members), rest}
  end

  @spec consume_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) :: bitstring()
  defp consume_description(_storage, _id, <<members_count::uint16, rest::binary>>) do
    {_members, rest} = DataTypes.String.decode(members_count, rest)
    rest
  end
end
