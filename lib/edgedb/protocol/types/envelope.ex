defmodule EdgeDB.Protocol.Types.Envelope do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Types

  @nelems 1

  deftype(
    name: :envelope,
    encode: false,
    fields: [
      elements: list(Types.ArrayElement.t())
    ]
  )

  @impl EdgeDB.Protocol.Type
  def decode_type(<<len::int32, @nelems::int32, _reserved::int32, rest::binary>>) do
    {elements, rest} = Types.ArrayElement.decode(len, rest)

    {envelope(elements: elements), rest}
  end
end
