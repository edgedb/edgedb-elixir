defmodule EdgeDB.Protocol.Types.DataElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.DataTypes

  deftype(
    encode?: false,
    name: :data_element,
    fields: [
      data: [DataTypes.UInt8.t()]
    ]
  )

  @spec decode(bitstring()) :: {t(), bitstring()}
  def decode(<<num_data::uint32, rest::binary>>) do
    {data, rest} = DataTypes.UInt8.decode(num_data, rest)

    data = [
      DataTypes.UInt32.encode(num_data),
      DataTypes.UInt8.encode(data, :raw)
    ]

    {data_element(data: IO.iodata_to_binary(data)), rest}
  end
end
