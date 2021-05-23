defmodule EdgeDB.Protocol.Types.TupleElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  @reserved 0
  @empty_set_element_length -1

  deftype(
    name: :tuple_element,
    fields: [
      data: [DataTypes.UInt8.t()] | :empty_set
    ]
  )

  @spec encode(t()) :: iodata()
  def encode(tuple_element(data: data)) do
    data =
      data
      |> IO.iodata_to_binary()
      |> :binary.bin_to_list()

    [
      DataTypes.Int32.encode(@reserved),
      DataTypes.UInt8.encode(data, raw: true)
    ]
  end

  @spec decode(bitstring()) :: {t(), bitstring()}

  def decode(<<_reserved::int32, @empty_set_element_length::int32, rest::binary>>) do
    {tuple_element(data: :empty_set), rest}
  end

  def decode(<<_reserved::int32, len::int32, rest::binary>>) do
    {data, rest} = DataTypes.UInt8.decode(len, rest)

    data = [
      DataTypes.UInt32.encode(len),
      DataTypes.UInt8.encode(data, raw: true)
    ]

    {tuple_element(data: IO.iodata_to_binary(data)), rest}
  end
end
