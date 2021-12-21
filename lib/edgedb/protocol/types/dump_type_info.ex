defmodule EdgeDB.Protocol.Types.DumpTypeInfo do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  deftype(
    name: :dump_type_info,
    encode: false,
    fields: [
      type_name: Datatypes.String.t(),
      type_class: Datatypes.String.t(),
      type_id: Datatypes.UUID.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def decode_type(<<data::binary>>) do
    {type_name, rest} = Datatypes.String.decode(data)
    {type_class, rest} = Datatypes.String.decode(rest)
    {type_id, rest} = Datatypes.UUID.decode(rest)
    {dump_type_info(type_name: type_name, type_class: type_class, type_id: type_id), rest}
  end
end
