defmodule EdgeDB.Protocol.Types.ProtocolExtension do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  deftype(
    name: :protocol_extension,
    fields: [
      name: DataTypes.String.t(),
      headers: [Types.Header.t()]
    ]
  )

  @spec encode(t()) :: iodata()
  def encode(protocol_extension(name: name, headers: headers)) do
    [
      DataTypes.String.encode(name),
      DataTypes.UInt16.encode(length(headers)),
      Enum.map(headers, &Types.Header.encode(&1))
    ]
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<data::binary>>) do
    {name, rest} = DataTypes.String.decode(data)
    {num_headers, rest} = DataTypes.UInt64.decode(rest)
    {headers, rest} = Types.Header.decode(num_headers, rest)

    {protocol_extension(name: name, headers: headers), rest}
  end
end
