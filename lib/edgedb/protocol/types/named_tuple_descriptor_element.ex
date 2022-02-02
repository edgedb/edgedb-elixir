defmodule EdgeDB.Protocol.Types.NamedTupleDescriptorElement do
  @moduledoc false

  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  deftype(
    encode: false,
    fields: [
      name: Datatypes.String.t(),
      type_pos: Datatypes.Int16.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def decode_type(<<data::binary>>) do
    {name, rest} = Datatypes.String.decode(data)
    {type_pos, rest} = Datatypes.Int16.decode(rest)

    {%__MODULE__{name: name, type_pos: type_pos}, rest}
  end
end
