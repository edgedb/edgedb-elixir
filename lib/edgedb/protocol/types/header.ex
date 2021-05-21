defmodule EdgeDB.Protocol.Types.Header do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  deftype(
    name: :header,
    fields: [
      code: DataTypes.UInt16.t(),
      value: DataTypes.Bytes.t()
    ]
  )

  @spec encode(t()) :: iodata()
  def encode(header(code: code, value: value)) do
    [DataTypes.UInt16.encode(code), DataTypes.Bytes.encode(value)]
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<code::uint16, rest::binary>>) do
    {value, rest} = DataTypes.Bytes.decode(rest)
    {header(code: code, value: value), rest}
  end
end
