defmodule EdgeDB.Protocol.TypeDescriptors.ScalarTypeNameAnnotation do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{Codecs, DataTypes}

  # id of type here is always known, so no need to parse
  deftypedescriptor(
    type: 0xFF,
    parse?: false
  )

  # update existing codec with type name information
  defp consume_description(storage, id, <<data::binary>>) do
    {type_name, rest} = DataTypes.String.decode(data)

    Codecs.Storage.update(storage, id, %{type_name: type_name})

    rest
  end
end
