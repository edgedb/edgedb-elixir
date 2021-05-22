defmodule EdgeDB.Protocol.Messages.Client.OptimisticExecute do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    DataTypes,
    Enums,
    Types
  }

  defmessage(
    name: :optimistic_execute,
    client: true,
    mtype: 0x4F,
    fields: [
      headers: [Types.Header.t()],
      io_format: Enums.IOFormat.t(),
      expected_cardinality: Enums.Cardinality.t(),
      command_text: DataTypes.String.t(),
      input_typedesc_id: DataTypes.UUID.t(),
      output_typedesc_id: DataTypes.UUID.t(),
      arguments: iodata()
    ],
    defaults: [
      headers: []
    ],
    known_headers: %{
      implicit_limit: 0xFF01,
      implicit_typenames: 0xFF02,
      implicit_typeids: 0xFF03,
      allow_capabilities: {0xFF04, &Enums.Capability.encode/1},
      explicit_objectids: 0xFF05
    }
  )

  @spec encode_message(t()) :: iodata()
  defp encode_message(
         optimistic_execute(
           headers: headers,
           io_format: io_format,
           expected_cardinality: expected_cardinality,
           command_text: command_text,
           input_typedesc_id: input_typedesc_id,
           output_typedesc_id: output_typedesc_id,
           arguments: arguments
         )
       ) do
    processed_headers = process_headers(headers)

    [
      Types.Header.encode(processed_headers),
      Enums.IOFormat.encode(io_format),
      Enums.Cardinality.encode(expected_cardinality),
      DataTypes.String.encode(command_text),
      DataTypes.UUID.encode(input_typedesc_id),
      DataTypes.UUID.encode(output_typedesc_id),
      arguments
    ]
  end
end
