defmodule EdgeDB.Protocol.Types.Envelope do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Types

  @nelems 1

  deftype(
    encode?: false,
    name: :envelope,
    fields: [
      elements: [Types.ArrayElement.t()]
    ]
  )

  def decode(<<len::int32, @nelems::int32, _reserved::int32, rest::binary>>) do
    {elements, rest} = Types.ArrayElement.decode(len, rest)

    {envelope(elements: elements), rest}
  end
end
