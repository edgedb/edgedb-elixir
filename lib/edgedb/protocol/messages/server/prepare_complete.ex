defmodule EdgeDB.Protocol.Messages.Server.PrepareComplete do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  defmessage(
    server: true,
    mtype: 0x31,
    fields: [
      headers: Keyword.t(),
      cardinality: Enums.Cardinality.t(),
      input_typedesc_id: Datatypes.UUID.t(),
      output_typedesc_id: Datatypes.UUID.t()
    ],
    known_headers: %{
      capabilities: [
        code: 0x1001,
        decoder: &Enums.Capability.exhaustive_decode/1
      ]
    }
  )

  @impl EdgeDB.Protocol.Message
  def decode_message(<<num_headers::uint16, rest::binary>>) do
    {headers, rest} = Types.Header.decode(num_headers, rest)
    {cardinality, rest} = Enums.Cardinality.decode(rest)
    {input_typedesc_id, rest} = Datatypes.UUID.decode(rest)
    {output_typedesc_id, <<>>} = Datatypes.UUID.decode(rest)

    %__MODULE__{
      headers: handle_headers(headers),
      cardinality: cardinality,
      input_typedesc_id: input_typedesc_id,
      output_typedesc_id: output_typedesc_id
    }
  end
end
