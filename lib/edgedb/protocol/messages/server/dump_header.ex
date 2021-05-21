defmodule EdgeDB.Protocol.Messages.Server.DumpHeader do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defmessage(
    name: :dump_header,
    server: true,
    mtype: 0x40,
    fields: [
      headers: [Types.Header.t()],
      major_ver: DataTypes.UInt16.t(),
      minor_ver: DataTypes.UInt16.t(),
      schema_ddl: DataTypes.String.t(),
      types: [Types.DumpTypeInfo.t()],
      descriptors: [Types.DumpObjectDesc.t()]
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {major_ver, rest} = DataTypes.UInt16.decode(rest)
    {minor_ver, rest} = DataTypes.UInt16.decode(rest)
    {schema_ddl, rest} = DataTypes.String.decode(rest)
    {num_types, rest} = DataTypes.UInt32.decode(rest)
    {types, rest} = Types.DumpTypeInfo.decode(num_types, rest)
    {num_descriptors, rest} = DataTypes.UInt32.decode(rest)
    {descriptors, <<>>} = Types.DumpObjectDesc.decode(num_descriptors, rest)

    dump_header(
      headers: headers,
      major_ver: major_ver,
      minor_ver: minor_ver,
      schema_ddl: schema_ddl,
      types: types,
      descriptors: descriptors
    )
  end
end
