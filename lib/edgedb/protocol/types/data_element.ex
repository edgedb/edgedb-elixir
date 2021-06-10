defmodule EdgeDB.Protocol.Types.DataElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  deftype(
    name: :data_element,
    encode?: false,
    fields: [
      data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def decode_type(<<num_data::uint32, rest::binary>>) do
    {data, rest} = Datatypes.UInt8.decode(num_data, rest)

    data = Datatypes.UInt8.encode(data, datatype: Datatypes.UInt32)
    {data_element(data: IO.iodata_to_binary(data)), rest}
  end
end
