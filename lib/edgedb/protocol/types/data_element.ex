defmodule EdgeDB.Protocol.Types.DataElement do
  @moduledoc false

  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  deftype(
    encode: false,
    fields: [
      data: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def decode_type(<<num_data::uint32, rest::binary>>) do
    {data, rest} = Datatypes.UInt8.decode(num_data, rest)

    data = Datatypes.UInt8.encode(data, datatype: Datatypes.UInt32)
    {%__MODULE__{data: IO.iodata_to_binary(data)}, rest}
  end
end
