defmodule EdgeDB.Protocol.Types.TupleElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  @reserved 0
  @empty_set_element_length -1

  deftype(
    name: :tuple_element,
    fields: [
      data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def encode_type(tuple_element(data: data)) do
    data =
      data
      |> IO.iodata_to_binary()
      |> :binary.bin_to_list()

    [
      Datatypes.Int32.encode(@reserved),
      Datatypes.UInt8.encode(data, raw: true)
    ]
  end

  @impl EdgeDB.Protocol.Type
  def decode_type(<<_reserved::int32, @empty_set_element_length::int32, rest::binary>>) do
    {tuple_element(data: :empty_set), rest}
  end

  @impl EdgeDB.Protocol.Type
  def decode_type(<<_reserved::int32, len::int32, rest::binary>>) do
    {data, rest} = Datatypes.UInt8.decode(len, rest)

    data = [
      Datatypes.UInt32.encode(len),
      Datatypes.UInt8.encode(data, raw: true)
    ]

    {tuple_element(data: IO.iodata_to_binary(data)), rest}
  end
end
