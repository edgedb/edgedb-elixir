defmodule EdgeDB.Protocol.Messages.Server.DumpHeader do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  defmessage(
    name: :dump_header,
    server: true,
    mtype: 0x40,
    fields: [
      headers: Keyword.t(),
      major_ver: Datatypes.UInt16.t(),
      minor_ver: Datatypes.UInt16.t(),
      schema_ddl: Datatypes.String.t(),
      types: list(Types.DumpTypeInfo.t()),
      descriptors: list(Types.DumpObjectDesc.t())
    ],
    known_headers: %{
      block_type: [
        code: 101
      ],
      block_id: [
        code: 102
      ],
      block_num: [
        code: 103
      ]
    }
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {major_ver, rest} = Datatypes.UInt16.decode(rest)
    {minor_ver, rest} = Datatypes.UInt16.decode(rest)
    {schema_ddl, rest} = Datatypes.String.decode(rest)
    {num_types, rest} = Datatypes.UInt32.decode(rest)
    {types, rest} = Types.DumpTypeInfo.decode(num_types, rest)
    {num_descriptors, rest} = Datatypes.UInt32.decode(rest)
    {descriptors, <<>>} = Types.DumpObjectDesc.decode(num_descriptors, rest)

    dump_header(
      headers: handle_headers(headers),
      major_ver: major_ver,
      minor_ver: minor_ver,
      schema_ddl: schema_ddl,
      types: types,
      descriptors: descriptors
    )
  end
end
