defmodule EdgeDB.Protocol.Messages.Client.OptimisticExecute do
  use EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Types
  }

  defmessage(
    client: true,
    mtype: 0x4F,
    fields: [
      headers: map(),
      io_format: Enums.IOFormat.t(),
      expected_cardinality: Enums.Cardinality.t(),
      command_text: Datatypes.String.t(),
      input_typedesc_id: Datatypes.UUID.t(),
      output_typedesc_id: Datatypes.UUID.t(),
      arguments: iodata()
    ],
    known_headers: %{
      implicit_limit: [
        code: 0xFF01
      ],
      implicit_typenames: [
        code: 0xFF02
      ],
      implicit_typeids: [
        code: 0xFF03
      ],
      allow_capabilities: [
        code: 0xFF04,
        encoder: Enums.Capability
      ],
      explicit_objectids: [
        code: 0xFF05
      ]
    }
  )

  @impl EdgeDB.Protocol.Message
  def encode_message(%__MODULE__{
        headers: headers,
        io_format: io_format,
        expected_cardinality: expected_cardinality,
        command_text: command_text,
        input_typedesc_id: input_typedesc_id,
        output_typedesc_id: output_typedesc_id,
        arguments: arguments
      }) do
    headers = handle_headers(headers)

    [
      Types.Header.encode(headers),
      Enums.IOFormat.encode(io_format),
      Enums.Cardinality.encode(expected_cardinality),
      Datatypes.String.encode(command_text),
      Datatypes.UUID.encode(input_typedesc_id),
      Datatypes.UUID.encode(output_typedesc_id),
      arguments
    ]
  end
end
