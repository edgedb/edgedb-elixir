defmodule EdgeDB.Protocol.Types.Header do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  deftype(
    fields: [
      code: Datatypes.UInt16.t(),
      value: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def encode_type(%__MODULE__{code: code, value: value}) do
    [Datatypes.UInt16.encode(code), Datatypes.Bytes.encode(value)]
  end

  @impl EdgeDB.Protocol.Type
  def decode_type(<<code::uint16, rest::binary>>) do
    {value, rest} = Datatypes.Bytes.decode(rest)
    {%__MODULE__{code: code, value: value}, rest}
  end
end
