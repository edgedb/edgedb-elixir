defmodule EdgeDB.Protocol.Types.TupleElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  @reserved 0
  @empty_set_element_length -1
  @empty_set [
    Datatypes.Int32.encode(@reserved),
    Datatypes.Int32.encode(@empty_set_element_length)
  ]

  deftype(
    fields: [
      data: Datatypes.Bytes.t() | :empty_set
    ]
  )

  @impl EdgeDB.Protocol.Type
  def encode_type(%__MODULE__{data: :empty_set}) do
    @empty_set
  end

  @impl EdgeDB.Protocol.Type
  def encode_type(%__MODULE__{data: data}) do
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
    {%__MODULE__{data: :empty_set}, rest}
  end

  @impl EdgeDB.Protocol.Type
  def decode_type(<<_reserved::int32, len::int32, rest::binary>>) do
    {data, rest} = Datatypes.UInt8.decode(len, rest)

    data = [
      Datatypes.UInt32.encode(len),
      Datatypes.UInt8.encode(data, raw: true)
    ]

    {%__MODULE__{data: IO.iodata_to_binary(data)}, rest}
  end
end
