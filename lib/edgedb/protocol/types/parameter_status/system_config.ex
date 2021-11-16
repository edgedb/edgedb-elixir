defmodule EdgeDB.Protocol.Types.ParameterStatus.SystemConfig do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  deftype(
    name: :system_config,
    encode?: false,
    fields: [
      typedesc_id: Datatypes.UUID.t(),
      typedesc: Datatypes.Bytes.t(),
      data: Types.DataElement.t()
    ]
  )

  @impl EdgeDB.Protocol.Type
  def decode_type(<<num_typedesc::uint32, rest::binary>>) do
    uuid_len = 16

    {typedesc_id, rest} = Datatypes.UUID.decode(rest)
    {typedesc, rest} = Datatypes.UInt8.decode(num_typedesc - uuid_len, rest)

    {data, rest} = Types.DataElement.decode(rest)

    typedesc =
      typedesc
      |> Datatypes.UInt8.encode(raw: true)
      |> IO.iodata_to_binary()

    {system_config(
       typedesc_id: typedesc_id,
       typedesc: typedesc,
       data: data
     ), rest}
  end
end
