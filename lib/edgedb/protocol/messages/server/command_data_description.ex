defmodule EdgeDB.Protocol.Messages.Server.CommandDataDescription do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  defmessage(
    server: true,
    mtype: 0x54,
    fields: [
      headers: Keyword.t(),
      result_cardinality: Enums.Cardinality.t(),
      input_typedesc_id: Datatypes.UUID.t(),
      input_typedesc: Datatypes.Bytes.t(),
      output_typedesc_id: Datatypes.UUID.t(),
      output_typedesc: Datatypes.Bytes.t()
    ]
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {cardinality, rest} = Enums.Cardinality.decode(rest)
    {input_typedesc_id, rest} = Datatypes.UUID.decode(rest)
    {input_typedesc, rest} = Datatypes.Bytes.decode(rest)
    {output_typedesc_id, rest} = Datatypes.UUID.decode(rest)
    {output_typedesc, <<>>} = Datatypes.Bytes.decode(rest)

    %__MODULE__{
      headers: handle_headers(headers),
      result_cardinality: cardinality,
      input_typedesc_id: input_typedesc_id,
      input_typedesc: input_typedesc,
      output_typedesc_id: output_typedesc_id,
      output_typedesc: output_typedesc
    }
  end
end
