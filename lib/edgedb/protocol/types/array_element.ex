defmodule EdgeDB.Protocol.Types.ArrayElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  deftype(
    name: :array_element,
    fields: [
      data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def encode_type(array_element(data: data)) do
    data =
      data
      |> IO.iodata_to_binary()
      |> :binary.bin_to_list()

    Datatypes.UInt8.encode(data, raw: true)
  end

  @impl EdgeDB.Protocol.Type
  def decode_type(<<len::int32, rest::binary>>) do
    {data, rest} = Datatypes.UInt8.decode(len, rest)

    data = Datatypes.UInt8.encode(data, datatype: Datatypes.UInt32)

    {array_element(data: IO.iodata_to_binary(data)), rest}
  end
end
