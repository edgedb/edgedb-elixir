defmodule EdgeDB.Protocol.Messages.Server.CommandDataDescription do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{DataTypes, Types, Enums}

  defmessage(
    server: true,
    mtype: 0x54,
    name: :command_data_description,
    fields: [
      headers: [Types.Header.t()],
      result_cardinality: Enums.Cardinality.t(),
      input_typedesc_id: DataTypes.UUID.t(),
      input_typedesc: DataTypes.Bytes.t(),
      output_typedesc_id: DataTypes.UUID.t(),
      output_typedesc: DataTypes.Bytes.t()
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {cardinality, rest} = Enums.Cardinality.decode(rest)
    {input_typedesc_id, rest} = DataTypes.UUID.decode(rest)
    {input_typedesc, rest} = DataTypes.Bytes.decode(rest)
    {output_typedesc_id, rest} = DataTypes.UUID.decode(rest)
    {output_typedesc, <<>>} = DataTypes.Bytes.decode(rest)

    command_data_description(
      headers: headers,
      result_cardinality: cardinality,
      input_typedesc_id: input_typedesc_id,
      input_typedesc: input_typedesc,
      output_typedesc_id: output_typedesc_id,
      output_typedesc: output_typedesc
    )
  end
end
