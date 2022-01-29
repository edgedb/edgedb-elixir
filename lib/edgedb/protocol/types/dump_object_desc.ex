defmodule EdgeDB.Protocol.Types.DumpObjectDesc do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  deftype(
    encode: false,
    fields: [
      object_id: Datatypes.UUID.t(),
      description: Datatypes.Bytes.t(),
      dependencies: list(Datatypes.UUID.t())
    ]
  )

  @impl EdgeDB.Protocol.Type
  def decode_type(<<object_id::uuid, rest::binary>>) do
    {description, rest} = Datatypes.Bytes.decode(rest)
    {num_dependencies, rest} = Datatypes.UInt16.decode(rest)
    {dependencies, rest} = Datatypes.UUID.decode(num_dependencies, rest)

    {
      %__MODULE__{
        object_id: Datatypes.UUID.to_string(object_id),
        description: description,
        dependencies: dependencies
      },
      rest
    }
  end
end
