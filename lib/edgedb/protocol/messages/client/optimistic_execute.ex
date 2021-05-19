defmodule EdgeDB.Protocol.Messages.Client.OptimisticExecute do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{DataTypes, Types, Enums}

  defmessage(
    client: true,
    mtype: 0x4F,
    name: :optimistic_execute,
    fields: [
      headers: [Types.Header.t()],
      io_format: Enums.IOFormat.t(),
      expected_cardinality: Enums.Cardinality.t(),
      command_text: DataTypes.String.t(),
      input_typedesc_id: DataTypes.UUID.t(),
      output_typedesc_id: DataTypes.UUID.t(),
      arguments: DataTypes.Bytes.t()
    ]
  )

  @spec encode_message(t()) :: bitstring()
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
      DataTypes.Bytes.encode(arguments)
    ]
  end
end
