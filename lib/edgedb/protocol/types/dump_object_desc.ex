defmodule EdgeDB.Protocol.Types.DumpObjectDesc do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  deftype(
    encode?: false,
    name: :dump_object_desc,
    fields: [
      object_id: DataTypes.UUID.t(),
      description: DataTypes.Bytes.t(),
      dependencies: [DataTypes.UUID.t()]
    ]
  )

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<object_id::uuid, rest::binary>>) do
    {description, rest} = DataTypes.Bytes.decode(rest)
    {num_dependencies, rest} = DataTypes.UInt16.decode(rest)
    {dependencies, rest} = DataTypes.UUID.decode(num_dependencies, rest)

    {
      dump_object_desc(
        object_id: object_id,
        description: description,
        dependencies: dependencies
      ),
      rest
    }
  end
end
