defmodule EdgeDB.Protocol.TypeDescriptors.ScalarTypeNameAnnotation do
  @moduledoc false

  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes
  }

  # id of type here is always known, so no need to parse
  deftypedescriptor(
    type: 0xFF,
    parse: false
  )

  # update existing codec with type name information
  @impl EdgeDB.Protocol.TypeDescriptor
  def consume_description(codecs_storage, id, <<data::binary>>) do
    {type_name, rest} = Datatypes.String.decode(data)

    Codecs.Storage.update(codecs_storage, id, %{type_name: type_name})

    rest
  end
end
