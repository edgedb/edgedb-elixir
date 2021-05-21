defmodule EdgeDB.Protocol.Types.NamedTupleDescriptorElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  deftype(
    name: :named_tuple_descriptor_element,
    encode?: false,
    fields: [
      name: DataTypes.String.t(),
      type_pos: DataTypes.UInt16.t()
    ]
  )

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<data::binary>>) do
    {name, rest} = DataTypes.String.decode(data)
    {type_pos, rest} = DataTypes.Int16.decode(rest)

    {named_tuple_descriptor_element(name: name, type_pos: type_pos), rest}
  end
end
