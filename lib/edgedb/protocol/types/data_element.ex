defmodule EdgeDB.Protocol.Types.DataElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  deftype(
    name: :data_element,
    encode?: false,
    fields: [
      data: binary()
    ]
  )

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<num_data::uint32, rest::binary>>) do
    {data, rest} = DataTypes.UInt8.decode(num_data, rest)

    data = DataTypes.UInt8.encode(data, data_type: DataTypes.UInt32)
    {data_element(data: IO.iodata_to_binary(data)), rest}
  end
end
