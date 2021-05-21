defmodule EdgeDB.Protocol.Messages.Server.PrepareComplete do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Enums,
    Types
  }

  defmessage(
    name: :prepare_complete,
    server: true,
    mtype: 0x31,
    fields: [
      headers: [Types.Header.t()],
      cardinality: Enums.Cardinality.t(),
      input_typedesc_id: DataTypes.UUID.t(),
      output_typedesc_id: DataTypes.UUID.t()
    ]
  )

  @spec decode_message(bitstring()) :: t()
  defp decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {cardinality, rest} = Enums.Cardinality.decode(rest)
    {input_typedesc_id, rest} = DataTypes.UUID.decode(rest)
    {output_typedesc_id, <<>>} = DataTypes.UUID.decode(rest)

    prepare_complete(
      headers: headers,
      cardinality: cardinality,
      input_typedesc_id: input_typedesc_id,
      output_typedesc_id: output_typedesc_id
    )
  end
end
