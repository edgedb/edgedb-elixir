defmodule EdgeDB.Protocol.Types.NamedTupleDescriptorElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  deftype(
    name: :named_tuple_descriptor_element,
    encode?: false,
    fields: [
      name: Datatypes.String.t(),
      type_pos: Datatypes.Int16.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def decode_type(<<data::binary>>) do
    {name, rest} = Datatypes.String.decode(data)
    {type_pos, rest} = Datatypes.Int16.decode(rest)

    {named_tuple_descriptor_element(name: name, type_pos: type_pos), rest}
  end
end
