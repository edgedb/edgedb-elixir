defmodule EdgeDB.Protocol.Types.ArrayElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  deftype(
    name: :array_element,
    fields: [
      data: iodata()
    ]
  )

  @spec encode(t()) :: iodata()
  def encode(array_element(data: data)) do
    data =
      data
      |> IO.iodata_to_binary()
      |> :binary.bin_to_list()

    DataTypes.UInt8.encode(data, raw: true)
  end

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<len::int32, rest::binary>>) do
    {data, rest} = DataTypes.UInt8.decode(len, rest)

    data = DataTypes.UInt8.encode(data, data_type: DataTypes.UInt32)

    {array_element(data: IO.iodata_to_binary(data)), rest}
  end
end
