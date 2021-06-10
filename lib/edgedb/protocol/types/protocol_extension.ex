defmodule EdgeDB.Protocol.Types.ProtocolExtension do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  deftype(
    name: :protocol_extension,
    fields: [
      name: Datatypes.String.t(),
      headers: list(Types.Header.t())
    ]
  )

  @impl EdgeDB.Protocol.Type
  def encode_type(protocol_extension(name: name, headers: headers)) do
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

    {protocol_extension(name: name, headers: headers), rest}
  end
end
