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
    ]
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
    [
      Types.Header.encode(headers),
      Enums.IOFormat.encode(io_format),
      Enums.Cardinality.encode(expected_cardinality),
      DataTypes.String.encode(command_text),
      DataTypes.UUID.encode(input_typedesc_id),
      DataTypes.UUID.encode(output_typedesc_id),
      arguments
    ]
  end
end
