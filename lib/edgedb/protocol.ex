defmodule EdgeDB.Protocol do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes
  }

  alias EdgeDB.Protocol.TypeDescriptors.TypeAnnotationDescriptor

  require TypeAnnotationDescriptor

  @type server_message() ::
          EdgeDB.Protocol.Messages.Server.Authentication.t()
          | EdgeDB.Protocol.Messages.Server.CommandComplete.t()
          | EdgeDB.Protocol.Messages.Server.CommandDataDescription.t()
          | EdgeDB.Protocol.Messages.Server.Data.t()
          | EdgeDB.Protocol.Messages.Server.DumpBlock.t()
          | EdgeDB.Protocol.Messages.Server.DumpHeader.t()
          | EdgeDB.Protocol.Messages.Server.ErrorResponse.t()
          | EdgeDB.Protocol.Messages.Server.LogMessage.t()
          | EdgeDB.Protocol.Messages.Server.ParameterStatus.t()
          | EdgeDB.Protocol.Messages.Server.PrepareComplete.t()
          | EdgeDB.Protocol.Messages.Server.ReadyForCommand.t()
          | EdgeDB.Protocol.Messages.Server.RestoreReady.t()
          | EdgeDB.Protocol.Messages.Server.ServerHandshake.t()
          | EdgeDB.Protocol.Messages.Server.ServerKeyData.t()

  # don't add here TypeAnnotationDescriptor since it supports multiple codes for type
  # TypeAnnotationDescriptor will be handled manually
  @type_descriptors [
    EdgeDB.Protocol.TypeDescriptors.SetDescriptor,
    EdgeDB.Protocol.TypeDescriptors.ObjectShapeDescriptor,
    EdgeDB.Protocol.TypeDescriptors.BaseScalarTypeDescriptor,
    EdgeDB.Protocol.TypeDescriptors.ScalarTypeDescriptor,
    EdgeDB.Protocol.TypeDescriptors.TupleTypeDescriptor,
    EdgeDB.Protocol.TypeDescriptors.NamedTupleTypeDescriptor,
    EdgeDB.Protocol.TypeDescriptors.ArrayTypeDescriptor,
    EdgeDB.Protocol.TypeDescriptors.EnumerationTypeDescriptor,
    EdgeDB.Protocol.TypeDescriptors.ScalarTypeNameAnnotation
  ]

  @types [
    EdgeDB.Protocol.Types.ConnectionParam,
    EdgeDB.Protocol.Types.Header,
    EdgeDB.Protocol.Types.DataElement,
    EdgeDB.Protocol.Types.ParameterStatus.SystemConfig
  ]

  @client_messages [
    EdgeDB.Protocol.Messages.Client.AuthenticationSASLInitialResponse,
    EdgeDB.Protocol.Messages.Client.AuthenticationSASLResponse,
    EdgeDB.Protocol.Messages.Client.ClientHandshake,
    EdgeDB.Protocol.Messages.Client.DescribeStatement,
    EdgeDB.Protocol.Messages.Client.Dump,
    EdgeDB.Protocol.Messages.Client.ExecuteScript,
    EdgeDB.Protocol.Messages.Client.Execute,
    EdgeDB.Protocol.Messages.Client.Flush,
    EdgeDB.Protocol.Messages.Client.OptimisticExecute,
    EdgeDB.Protocol.Messages.Client.Prepare,
    EdgeDB.Protocol.Messages.Client.RestoreBlock,
    EdgeDB.Protocol.Messages.Client.RestoreEOF,
    EdgeDB.Protocol.Messages.Client.Restore,
    EdgeDB.Protocol.Messages.Client.Sync,
    EdgeDB.Protocol.Messages.Client.Terminate
  ]

  @server_messages [
    EdgeDB.Protocol.Messages.Server.Authentication,
    EdgeDB.Protocol.Messages.Server.CommandComplete,
    EdgeDB.Protocol.Messages.Server.CommandDataDescription,
    EdgeDB.Protocol.Messages.Server.Data,
    EdgeDB.Protocol.Messages.Server.DumpBlock,
    EdgeDB.Protocol.Messages.Server.DumpHeader,
    EdgeDB.Protocol.Messages.Server.ErrorResponse,
    EdgeDB.Protocol.Messages.Server.LogMessage,
    EdgeDB.Protocol.Messages.Server.ParameterStatus,
    EdgeDB.Protocol.Messages.Server.PrepareComplete,
    EdgeDB.Protocol.Messages.Server.ReadyForCommand,
    EdgeDB.Protocol.Messages.Server.RestoreReady,
    EdgeDB.Protocol.Messages.Server.ServerHandshake,
    EdgeDB.Protocol.Messages.Server.ServerKeyData
  ]

  defmacro __using__(_opts \\ []) do
    types_import_def = define_types_import()
    client_messages_import_def = define_client_messages_import()
    server_messages_import_def = define_server_messages_import()

    quote do
      unquote(types_import_def)
      unquote(client_messages_import_def)
      unquote(server_messages_import_def)
    end
  end

  for client_message_mod <- @client_messages do
    @spec encode_message(unquote(client_message_mod).t()) :: iodata()
    def encode_message(message) when elem(message, 0) == unquote(client_message_mod.name()) do
      unquote(client_message_mod).encode(message)
    end
  end

  @spec decode_message(bitstring()) ::
          {:ok, {server_message(), bitstring()}} | {:error, {:not_enough_size, 0}}

  def decode_message(data) when byte_size(data) < 5 do
    {:error, {:not_enough_size, 0}}
  end

  for server_message_mod <- @server_messages do
    def decode_message(<<unquote(server_message_mod.mtype())::uint8, _rest::binary>> = data) do
      unquote(server_message_mod).decode(data)
    end
  end

  @spec build_codec_from_type_description(EdgeDB.Protocol.Codecs.Storage.t(), bitstring()) ::
          EdgeDB.Protocol.Codec.t()
  def build_codec_from_type_description(storage, type_description) do
    build_codec_from_type_description(storage, type_description, [])
  end

  defp build_codec_from_type_description(_storage, <<>>, [codec | _codecs]) do
    codec
  end

  defp build_codec_from_type_description(
         storage,
         <<_type::uint8, type_id::uuid, _rest::binary>> = type_description,
         codecs
       ) do
    type_id = Datatypes.UUID.from_integer(type_id)

    {codec, data} =
      case Codecs.Storage.get(storage, type_id) do
        nil ->
          {codec, rest} =
            parse_type_description_into_codec(
              codecs,
              type_description
            )

          Codecs.Storage.register(storage, codec)
          {codec, rest}

        codec ->
          rest = consume_type_description(storage, type_description)
          {codec, rest}
      end

    build_codec_from_type_description(storage, data, [codec | codecs])
  end

  for descriptor_mod <- @type_descriptors, descriptor_mod.support_parsing?() do
    defp parse_type_description_into_codec(
           codecs,
           <<unquote(descriptor_mod.type())::uint8, _rest::binary>> = type_description
         ) do
      unquote(descriptor_mod).parse(codecs, type_description)
    end
  end

  for descriptor_mod <- @type_descriptors, descriptor_mod.support_consuming?() do
    defp consume_type_description(
           codecs_storage,
           <<unquote(descriptor_mod.type())::uint8, _rest::binary>> = type_description
         ) do
      unquote(descriptor_mod).consume(codecs_storage, type_description)
    end
  end

  defp consume_type_description(codecs_storage, <<type::uint8, _rest::binary>> = type_description)
       when TypeAnnotationDescriptor.is_supported_type(type) do
    TypeAnnotationDescriptor.consume(
      codecs_storage,
      type_description
    )
  end

  defp define_types_import do
    for type_mod <- @types do
      define_record_import(type_mod)
    end
  end

  defp define_client_messages_import do
    for client_message_mod <- @client_messages do
      define_record_import(client_message_mod)
    end
  end

  defp define_server_messages_import do
    server_messages = @server_messages -- [EdgeDB.Protocol.Messages.Server.Authentication]

    server_messages = [
      EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationOK,
      EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationSASL,
      EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationSASLContinue,
      EdgeDB.Protocol.Messages.Server.Authentication.AuthenticationSASLFinal
      | server_messages
    ]

    for server_message_mod <- server_messages do
      define_record_import(server_message_mod)
    end
  end

  defp define_record_import(mod) do
    name = mod.name()

    quote do
      import unquote(mod), only: [{unquote(name), 0}, {unquote(name), 1}]
    end
  end
end
