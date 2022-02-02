defmodule EdgeDB.Protocol.Types.ProtocolExtension do
  @moduledoc false

  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  deftype(
    fields: [
      name: Datatypes.String.t(),
      headers: list(Types.Header.t())
    ]
  )

  @impl EdgeDB.Protocol.Type
  def encode_type(%__MODULE__{name: name, headers: headers}) do
    [
      Datatypes.String.encode(name),
      Datatypes.UInt16.encode(length(headers)),
      Enum.map(headers, &Types.Header.encode(&1))
    ]
  end

  @impl EdgeDB.Protocol.Type
  def decode_type(<<data::binary>>) do
    {name, rest} = Datatypes.String.decode(data)
    {num_headers, rest} = Datatypes.UInt64.decode(rest)
    {headers, rest} = Types.Header.decode(num_headers, rest)

    {%__MODULE__{name: name, headers: headers}, rest}
  end
end
