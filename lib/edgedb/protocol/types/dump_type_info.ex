defmodule EdgeDB.Protocol.Types.DumpTypeInfo do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  deftype(
    name: :dump_type_info,
    encode?: false,
    fields: [
      type_name: DataTypes.String.t(),
      type_class: DataTypes.String.t(),
      type_id: DataTypes.UUID.t()
    ]
  )

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<data::binary>>) do
    {type_name, rest} = DataTypes.String.decode(data)
    {type_class, rest} = DataTypes.String.decode(rest)
    {type_id, rest} = DataTypes.UUID.decode(rest)
    {dump_type_info(type_name: type_name, type_class: type_class, type_id: type_id), rest}
  end
end
