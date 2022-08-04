defmodule EdgeDB.Protocol do
  @moduledoc false

  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    CodecStorage,
    Types
  }

  alias EdgeDB.Protocol.Messages.{
    Client,
    Server
  }

  @type message_code() :: pos_integer()
  @type protocol_version() :: non_neg_integer()

  @type client_message() ::
          Client.V0.Flush.t()
          | Client.V0.Prepare.t()
          | Client.V0.DescribeStatement.t()
          | Client.V0.Execute.t()
          | Client.V0.OptimisticExecute.t()
          | Client.V0.ExecuteScript.t()
          | Client.AuthenticationSASLInitialResponse.t()
          | Client.AuthenticationSASLResponse.t()
          | Client.ClientHandshake.t()
          | Client.Parse.t()
          | Client.Execute.t()
          | Client.Sync.t()
          | Client.Terminate.t()

  @type server_message() ::
          Server.V0.PrepareComplete.t()
          | Server.AuthenticationOK.t()
          | Server.AuthenticationSASL.t()
          | Server.AuthenticationSASLContinue.t()
          | Server.AuthenticationSASLFinal.t()
          | Server.CommandComplete.t()
          | Server.CommandDataDescription.t()
          | Server.StateDataDescription.t()
          | Server.Data.t()
          | Server.ErrorResponse.t()
          | Server.LogMessage.t()
          | Server.ParameterStatus.t()
          | Server.ReadyForCommand.t()
          | Server.ServerHandshake.t()
          | Server.ServerKeyData.t()

  @json_library Application.compile_env(:edgedb, :json, Jason)

  @message_header_length 5

  @spec message_header_length() :: unquote(@message_header_length)
  def message_header_length do
    @message_header_length
  end

  @spec parse_message_header(bitstring()) :: {message_code(), non_neg_integer()}
  def parse_message_header(<<type::uint8, payload_length::int32>>) do
    {type, payload_length - 4}
  end

  @spec encode_message(client_message(), protocol_version()) :: iodata()
  def encode_message(message, protocol) do
    {type, payload} = do_message_encoding(message, protocol)

    [
      type,
      <<IO.iodata_length(payload) + 4::int32>>,
      payload
    ]
  end

  @spec decode_message(message_code(), bitstring(), protocol_version()) :: server_message()
  def decode_message(type, payload, protocol) do
    do_message_decoding(type, payload, protocol)
  end

  @spec parse_type_description(bitstring(), CodecStorage.t()) :: Codec.id()
  def parse_type_description(type_description, codec_storage) do
    do_type_description_parsing(type_description, codec_storage, %{})
  end

  defp do_message_encoding(%Client.V0.Flush{}, 0) do
    {0x48, []}
  end

  defp do_message_encoding(%Client.V0.Prepare{} = message, 0) do
    headers = map_into_key_value_list(:v0_prepare, message.headers)

    {0x50,
     [
       encode_key_value_list(headers),
       encode_enum(:output_format, message.io_format),
       encode_enum(:cardinality, message.expected_cardinality),
       <<0::uint32>>,
       <<byte_size(message.command)::uint32>>,
       message.command
     ]}
  end

  defp do_message_encoding(%Client.V0.DescribeStatement{} = message, 0) do
    headers = map_into_key_value_list(:v0_describe_statement, message.headers)

    {0x44,
     [
       encode_key_value_list(headers),
       encode_enum(:describe_aspect, message.aspect),
       <<0::uint32>>
     ]}
  end

  defp do_message_encoding(%Client.V0.Execute{} = message, 0) do
    headers = map_into_key_value_list(:v0_execute, message.headers)

    {0x45,
     [
       encode_key_value_list(headers),
       <<0::uint32>>,
       message.arguments
     ]}
  end

  defp do_message_encoding(%Client.V0.OptimisticExecute{} = message, 0) do
    headers = map_into_key_value_list(:v0_optimisitc_execute, message.headers)

    {0x4F,
     [
       encode_key_value_list(headers),
       encode_enum(:output_format, message.io_format),
       encode_enum(:cardinality, message.expected_cardinality),
       <<byte_size(message.command_text)::uint32>>,
       message.command_text,
       message.input_typedesc_id,
       message.output_typedesc_id,
       message.arguments
     ]}
  end

  defp do_message_encoding(%Client.V0.ExecuteScript{} = message, 0) do
    headers = map_into_key_value_list(:v0_execute_script, message.headers)

    {0x51,
     [
       encode_key_value_list(headers),
       <<byte_size(message.script)::uint32>>,
       message.script
     ]}
  end

  defp do_message_encoding(%Client.AuthenticationSASLInitialResponse{} = message, _protocol) do
    {0x70,
     [
       <<byte_size(message.method)::uint32>>,
       message.method,
       <<byte_size(message.sasl_data)::uint32>>,
       message.sasl_data
     ]}
  end

  defp do_message_encoding(%Client.AuthenticationSASLResponse{} = message, _protocol) do
    {0x72,
     [
       <<byte_size(message.sasl_data)::uint32>>,
       message.sasl_data
     ]}
  end

  # EdgeDB 1.0 doesn't define any extensions, so it's safe to encode them as empty list
  defp do_message_encoding(%Client.ClientHandshake{} = message, 0) do
    {0x56,
     [
       <<message.major_ver::uint16, message.minor_ver::uint16>>,
       encode_connection_param_list(message.params),
       <<0::uint16>>
     ]}
  end

  defp do_message_encoding(%Client.ClientHandshake{} = message, _protocol) do
    {0x56,
     [
       <<message.major_ver::uint16, message.minor_ver::uint16>>,
       encode_connection_param_list(message.params),
       encode_extension_list(message.extensions)
     ]}
  end

  defp do_message_encoding(%Client.Parse{} = message, _protocol) do
    annotations = map_into_annotation_list(message.annotations)

    {0x50,
     [
       encode_annotation_list(annotations),
       <<process_capabilities(message.allowed_capabilities)::uint64>>,
       <<process_compilation_flags(message.compilation_flags)::uint64>>,
       <<message.implicit_limit::uint64>>,
       encode_enum(:output_format, message.output_format),
       encode_enum(:cardinality, message.expected_cardinality),
       <<byte_size(message.command_text)::uint32>>,
       message.command_text,
       message.state_typedesc_id,
       message.state_data
     ]}
  end

  defp do_message_encoding(%Client.Execute{} = message, _protocol) do
    annotations = map_into_annotation_list(message.annotations)

    {0x4F,
     [
       encode_annotation_list(annotations),
       <<process_capabilities(message.allowed_capabilities)::uint64>>,
       <<process_compilation_flags(message.compilation_flags)::uint64>>,
       <<message.implicit_limit::uint64>>,
       encode_enum(:output_format, message.output_format),
       encode_enum(:cardinality, message.expected_cardinality),
       <<byte_size(message.command_text)::uint32>>,
       message.command_text,
       message.state_typedesc_id,
       message.state_data,
       message.input_typedesc_id,
       message.output_typedesc_id,
       message.arguments
     ]}
  end

  defp do_message_encoding(%Client.Sync{}, _protocol) do
    {0x53, []}
  end

  defp do_message_encoding(%Client.Terminate{}, _protocol) do
    {0x58, []}
  end

  defp do_message_decoding(0x31, <<data::binary>>, 0) do
    {headers,
     <<
       cardinality::uint8,
       input_typedesc_id::uuid,
       output_typedesc_id::uuid
     >>} = decode_key_value_list(data)

    %Server.V0.PrepareComplete{
      headers: key_value_list_into_map(:v0_prepare_complete, headers),
      cardinality: decode_enum(:cardinality, cardinality),
      input_typedesc_id: input_typedesc_id,
      output_typedesc_id: output_typedesc_id
    }
  end

  defp do_message_decoding(0x52, <<auth_status::uint32>>, _protocol) do
    %Server.AuthenticationOK{auth_status: auth_status}
  end

  defp do_message_decoding(0x52, <<0xA::uint32, num_methods::uint32, rest::binary>>, _protocol) do
    {methods, <<>>} = decode_string_list(rest, num_methods, [])
    %Server.AuthenticationSASL{auth_status: 0xA, methods: methods}
  end

  defp do_message_decoding(
         0x52,
         <<0xB::uint32, sasl_data_size::uint32, sasl_data::binary(sasl_data_size)>>,
         _protocol
       ) do
    %Server.AuthenticationSASLContinue{auth_status: 0xB, sasl_data: sasl_data}
  end

  defp do_message_decoding(
         0x52,
         <<0xC::uint32, sasl_data_size::uint32, sasl_data::binary(sasl_data_size)>>,
         _protocol
       ) do
    %Server.AuthenticationSASLFinal{auth_status: 0xB, sasl_data: sasl_data}
  end

  defp do_message_decoding(0x43, <<data::binary>>, 0) do
    {headers, <<status_size::uint32, status::binary(status_size)>>} = decode_key_value_list(data)

    %Server.CommandComplete{
      status: status,
      __headers__: key_value_list_into_map(:v0_command_complete, headers)
    }
  end

  defp do_message_decoding(0x43, <<data::binary>>, _protocol) do
    {annotations, <<rest::binary>>} = decode_annotation_list(data)

    <<
      capabilities::uint64,
      status_size::uint32,
      status::binary(status_size),
      state_typedesc_id::uuid,
      state_data_size::uint32,
      state_data::binary(state_data_size)
    >> = rest

    %Server.CommandComplete{
      annotations: annotations,
      capabilities: process_capabilities(capabilities),
      status: status,
      state_typedesc_id: state_typedesc_id,
      state_data: state_data
    }
  end

  defp do_message_decoding(0x54, <<data::binary>>, 0) do
    {headers,
     <<
       result_cardinality::uint8,
       input_typedesc_id::uuid,
       input_typedesc_size::uint32,
       input_typedesc::binary(input_typedesc_size),
       output_typedesc_id::uuid,
       output_typedesc_size::uint32,
       output_typedesc::binary(output_typedesc_size)
     >>} = decode_key_value_list(data)

    %Server.CommandDataDescription{
      result_cardinality: decode_enum(:cardinality, result_cardinality),
      input_typedesc_id: input_typedesc_id,
      input_typedesc: input_typedesc,
      output_typedesc_id: output_typedesc_id,
      output_typedesc: output_typedesc,
      __headers__: key_value_list_into_map(:v0_command_data_description, headers)
    }
  end

  defp do_message_decoding(0x54, <<data::binary>>, _protocol) do
    {annotations,
     <<
       capabilities::uint64,
       result_cardinality::uint8,
       input_typedesc_id::uuid,
       input_typedesc_size::uint32,
       input_typedesc::binary(input_typedesc_size),
       output_typedesc_id::uuid,
       output_typedesc_size::uint32,
       output_typedesc::binary(output_typedesc_size)
     >>} = decode_annotation_list(data)

    %Server.CommandDataDescription{
      annotations: annotations,
      capabilities: process_capabilities(capabilities),
      result_cardinality: decode_enum(:cardinality, result_cardinality),
      input_typedesc_id: input_typedesc_id,
      input_typedesc: input_typedesc,
      output_typedesc_id: output_typedesc_id,
      output_typedesc: output_typedesc
    }
  end

  defp do_message_decoding(
         0x73,
         <<typedesc_id::uuid, typedesc_size::uint32, typedesc::binary(typedesc_size)>>,
         _protocol
       ) do
    %Server.StateDataDescription{typedesc_id: typedesc_id, typedesc: typedesc}
  end

  defp do_message_decoding(0x44, <<data::binary>>, _protocol) do
    {data, <<>>} = decode_data_element_list(data)
    %Server.Data{data: data}
  end

  defp do_message_decoding(0x45, <<severity::uint8, error_code::uint32, rest::binary>>, _protocol) do
    <<message_size::uint32, message::binary(message_size), rest::binary>> = rest
    {attributes, <<>>} = decode_key_value_list(rest)

    %Server.ErrorResponse{
      error_code: error_code,
      severity: decode_enum(:error_severity, severity),
      message: message,
      attributes: key_value_list_into_map(:error_response, attributes)
    }
  end

  defp do_message_decoding(0x4C, <<severity::uint8, code::uint32, rest::binary>>, 0) do
    <<text_size::uint32, text::binary(text_size), rest::binary>> = rest
    {annotations, <<>>} = decode_key_value_list(rest)

    %Server.LogMessage{
      code: code,
      severity: decode_enum(:message_severity, severity),
      text: text,
      annotations: key_value_list_into_map(:log_message, annotations)
    }
  end

  defp do_message_decoding(0x4C, <<severity::uint8, code::uint32, rest::binary>>, _protocol) do
    <<text_size::uint32, text::binary(text_size), rest::binary>> = rest
    {annotations, <<>>} = decode_annotation_list(rest)

    %Server.LogMessage{
      code: code,
      severity: decode_enum(:message_severity, severity),
      text: text,
      annotations: annotations
    }
  end

  defp do_message_decoding(
         0x53,
         <<
           name_size::uint32,
           name::binary(name_size),
           value_size::uint32,
           value::binary(value_size)
         >>,
         _protocol
       ) do
    %Server.ParameterStatus{name: name, value: decode_parameter_status_value(name, value)}
  end

  defp do_message_decoding(0x5A, <<data::binary>>, 0) do
    {headers, <<transaction_state::uint8>>} = decode_key_value_list(data)

    %Server.ReadyForCommand{
      transaction_state: decode_enum(:transaction_state, transaction_state),
      __headers__: headers
    }
  end

  defp do_message_decoding(0x5A, <<data::binary>>, _protocol) do
    {annotations, <<transaction_state::uint8>>} = decode_annotation_list(data)

    %Server.ReadyForCommand{
      annotations: annotations,
      transaction_state: decode_enum(:transaction_state, transaction_state)
    }
  end

  # EdgeDB 1.0 doesn't define any extensions, so it's safe to decode them as empty list
  defp do_message_decoding(0x76, <<major_ver::uint16, minor_ver::uint16, 0::uint16>>, 0) do
    %Server.ServerHandshake{
      major_ver: major_ver,
      minor_ver: minor_ver,
      extensions: []
    }
  end

  defp do_message_decoding(
         0x76,
         <<major_ver::uint16, minor_ver::uint16, rest::binary>>,
         _protocol
       ) do
    {extensions, <<>>} = decode_extension_list(rest)

    %Server.ServerHandshake{
      major_ver: major_ver,
      minor_ver: minor_ver,
      extensions: extensions
    }
  end

  defp do_message_decoding(0x4B, <<data::binary(32)>>, _protocol) do
    %Server.ServerKeyData{data: data}
  end

  defp do_type_description_parsing(<<type::uint8, id::uuid, data::binary>>, codec_storage, codecs) do
    rest =
      case CodecStorage.get(codec_storage, id) do
        nil ->
          {codec, rest} = do_codec_parsing(type, data, id, codecs, true)
          CodecStorage.add(codec_storage, id, codec)
          rest

        _codec ->
          {_codec, rest} = do_codec_parsing(type, data, id, codecs, false)
          rest
      end

    do_type_description_parsing(rest, codec_storage, Map.put(codecs, map_size(codecs), id))
  end

  defp do_type_description_parsing(<<>>, _codec_storage, codecs) do
    codecs[map_size(codecs) - 1]
  end

  defp do_codec_parsing(0, <<type_pos::uint16, rest::binary>>, id, codecs, create?) do
    codec =
      if create? do
        Codecs.Set.new(id, codecs[type_pos])
      else
        nil
      end

    {codec, rest}
  end

  defp do_codec_parsing(1, <<data::binary>>, id, codecs, create?) do
    {shape_elements, rest} = decode_shape_element_list(data)
    codecs = Enum.map(shape_elements, &codecs[&1.type_pos])

    codec =
      if create? do
        Codecs.Object.new(id, shape_elements, codecs, false)
      else
        nil
      end

    {codec, rest}
  end

  defp do_codec_parsing(2, <<rest::binary>>, _id, _codecs, false) do
    {nil, rest}
  end

  defp do_codec_parsing(3, <<base_type_pos::uint16, rest::binary>>, id, codecs, create?) do
    codec =
      if create? do
        Codecs.Scalar.new(id, codecs[base_type_pos])
      else
        nil
      end

    {codec, rest}
  end

  defp do_codec_parsing(4, <<data::binary>>, id, codecs, create?) do
    {element_types, rest} = decode_uint16_list(data)
    codecs = Enum.map(element_types, &codecs[&1])

    codec =
      if create? do
        Codecs.Tuple.new(id, codecs)
      else
        nil
      end

    {codec, rest}
  end

  defp do_codec_parsing(5, <<data::binary>>, id, codecs, create?) do
    {elements, rest} = decode_tuple_element_list(data)
    codecs = Enum.map(elements, &codecs[&1.type_pos])

    codec =
      if create? do
        Codecs.NamedTuple.new(id, elements, codecs)
      else
        nil
      end

    {codec, rest}
  end

  defp do_codec_parsing(6, <<type_pos::uint16, rest::binary>>, id, codecs, create?) do
    {dimensions, rest} = decode_int32_list(rest)

    codec =
      if create? do
        Codecs.Array.new(id, codecs[type_pos], dimensions)
      else
        nil
      end

    {codec, rest}
  end

  defp do_codec_parsing(7, <<data::binary>>, id, _codecs, create?) do
    {members, rest} = decode_string_list(data)

    codec =
      if create? do
        Codecs.Enum.new(id, members)
      else
        nil
      end

    {codec, rest}
  end

  defp do_codec_parsing(8, <<data::binary>>, id, codecs, create?) do
    {shape_elements, rest} = decode_shape_element_list(data)
    codecs = Enum.map(shape_elements, &codecs[&1.type_pos])

    codec =
      if create? do
        Codecs.Object.new(id, shape_elements, codecs, true)
      else
        nil
      end

    {codec, rest}
  end

  defp do_codec_parsing(9, <<type_pos::uint16, rest::binary>>, id, codecs, create?) do
    sub_codec = codecs[type_pos]

    codec =
      if create? do
        Codecs.Range.new(id, sub_codec)
      else
        nil
      end

    {codec, rest}
  end

  defp do_codec_parsing(
         0xFF,
         <<type_name_size::uint32, _type_name::binary(type_name_size), rest::binary>>,
         _id,
         _codecs,
         false
       ) do
    {nil, rest}
  end

  defp do_codec_parsing(
         type,
         <<annotation_size::uint32, _annotation::binary(annotation_size), rest::binary>>,
         _id,
         _codecs,
         false
       )
       when type in 0x80..0xFE do
    {nil, rest}
  end

  defp decode_parameter_status_value("system_config", data) do
    do_system_config_decoding(data)
  end

  defp decode_parameter_status_value("suggested_pool_concurrency", data) do
    {suggested_pool_concurrency, ""} = Integer.parse(data)
    suggested_pool_concurrency
  end

  defp decode_parameter_status_value(_name, data) do
    data
  end

  defp do_system_config_decoding(<<num_typedesc::uint32, rest::binary>>) do
    typedesc_size = num_typedesc - 16

    <<typedesc_id::uuid, typedesc::binary(typedesc_size), rest::binary>> = rest
    {[data], <<>>} = decode_data_element_list(rest, 1, [])

    %Types.ParameterStatus.SystemConfig{
      typedesc_id: typedesc_id,
      typedesc: typedesc,
      data: data
    }
  end

  defp encode_key_value_list(headers) do
    data =
      for header <- headers do
        [<<header.code::uint16, byte_size(header.value)::uint32>>, header.value]
      end

    [<<length(headers)::uint16>> | data]
  end

  defp decode_key_value_list(<<num_headers::uint16, data::binary>>) do
    decode_key_value_list(data, num_headers, [])
  end

  defp decode_key_value_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_key_value_list(<<data::binary>>, count, acc) do
    <<code::uint16, value_size::uint32, value::binary(value_size), rest::binary>> = data
    decode_key_value_list(rest, count - 1, [%Types.KeyValue{code: code, value: value} | acc])
  end

  defp encode_annotation_list(annotations) do
    data =
      for annotation <- annotations do
        value = @json_library.encode!(annotation.value)

        [
          <<
            byte_size(annotation.name)::uint32,
            annotation.name::binary,
            byte_size(value)::uint32,
            value::binary
          >>
        ]
      end

    [<<length(annotations)::uint16>> | data]
  end

  defp decode_annotation_list(<<num_annotations::uint16, data::binary>>) do
    decode_annotation_list(data, num_annotations, [])
  end

  defp decode_annotation_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_annotation_list(<<data::binary>>, count, acc) do
    <<name::uint16, value_size::uint32, value::binary(value_size), rest::binary>> = data

    decode_annotation_list(rest, count - 1, [
      %Types.Annotation{name: name, value: @json_library.decode!(value)} | acc
    ])
  end

  defp decode_data_element_list(<<num_data::uint16, data::binary>>) do
    decode_data_element_list(data, num_data, [])
  end

  defp decode_data_element_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_data_element_list(
         <<num_data::uint32, data::binary(num_data), rest::binary>>,
         count,
         acc
       ) do
    decode_data_element_list(rest, count - 1, [
      %Types.DataElement{data: <<num_data::uint32, data::binary>>} | acc
    ])
  end

  defp encode_connection_param_list(params) do
    data =
      for param <- params do
        [
          <<byte_size(param.name)::uint32>>,
          param.name,
          <<byte_size(param.value)::uint32>>,
          param.value
        ]
      end

    [<<length(params)::uint16>> | data]
  end

  defp encode_extension_list(extensions) do
    data =
      for extension <- extensions do
        annotations = map_into_annotation_list(extension.annotations)

        [
          <<byte_size(extension.name)::uint32>>,
          extension.name,
          annotations
        ]
      end

    [<<length(extensions)::uint16>> | data]
  end

  defp decode_extension_list(<<num_extensions::uint16, data::binary>>) do
    decode_extension_list(data, num_extensions, [])
  end

  defp decode_extension_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_extension_list(
         <<name_size::uint32, name::binary(name_size), rest::binary>>,
         count,
         acc
       ) do
    {annotations, rest} = decode_annotation_list(rest)

    decode_data_element_list(rest, count - 1, [
      %Types.ProtocolExtension{name: name, annotations: annotation_list_into_map(annotations)}
      | acc
    ])
  end

  defp decode_string_list(<<num_strings::uint16, data::binary>>) do
    decode_string_list(data, num_strings, [])
  end

  defp decode_string_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_string_list(<<data::binary>>, count, acc) do
    <<string_size::uint32, string::binary(string_size), rest::binary>> = data
    decode_string_list(rest, count - 1, [string | acc])
  end

  defp decode_shape_element_list(<<element_count::uint16, data::binary>>) do
    decode_shape_element_list(data, element_count, [])
  end

  defp decode_shape_element_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_shape_element_list(<<data::binary>>, count, acc) do
    <<
      flags::uint32,
      cardinality::uint8,
      name_size::uint32,
      name::binary(name_size),
      type_pos::uint16,
      rest::binary
    >> = data

    decode_shape_element_list(rest, count - 1, [
      %Types.ShapeElement{
        flags: flags,
        cardinality: decode_enum(:cardinality, cardinality),
        name: name,
        type_pos: type_pos
      }
      | acc
    ])
  end

  defp decode_uint16_list(<<element_count::uint16, data::binary>>) do
    decode_uint16_list(data, element_count, [])
  end

  defp decode_uint16_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_uint16_list(<<element_type::uint16, rest::binary>>, count, acc) do
    decode_uint16_list(rest, count - 1, [element_type | acc])
  end

  defp decode_int32_list(<<element_count::uint16, data::binary>>) do
    decode_int32_list(data, element_count, [])
  end

  defp decode_int32_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_int32_list(<<element::int32, rest::binary>>, count, acc) do
    decode_int32_list(rest, count - 1, [element | acc])
  end

  defp decode_tuple_element_list(<<element_count::uint16, data::binary>>) do
    decode_tuple_element_list(data, element_count, [])
  end

  defp decode_tuple_element_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_tuple_element_list(<<data::binary>>, count, acc) do
    <<name_size::uint32, name::binary(name_size), type_pos::uint16, rest::binary>> = data

    decode_tuple_element_list(rest, count - 1, [
      %Types.TupleElement{name: name, type_pos: type_pos} | acc
    ])
  end

  defp map_into_key_value_list(:v0_execute_script, headers) do
    Enum.reduce(headers, [], fn
      {:allow_capabilities, capabilities}, headers ->
        [
          %Types.KeyValue{code: 0xFF04, value: <<process_capabilities(capabilities)::uint64>>}
          | headers
        ]

      _header, headers ->
        headers
    end)
  end

  defp map_into_key_value_list(:v0_optimisitc_execute, headers) do
    Enum.reduce(headers, [], fn
      {:implicit_limit, value}, headers ->
        [%Types.KeyValue{code: 0xFF01, value: value} | headers]

      {:implicit_typenames, value}, headers ->
        [%Types.KeyValue{code: 0xFF02, value: value} | headers]

      {:implicit_typeids, value}, headers ->
        [%Types.KeyValue{code: 0xFF03, value: value} | headers]

      {:allow_capabilities, capabilities}, headers ->
        [
          %Types.KeyValue{code: 0xFF04, value: <<process_capabilities(capabilities)::uint64>>}
          | headers
        ]

      {:explicit_objectids, value}, headers ->
        [%Types.KeyValue{code: 0xFF05, value: value} | headers]

      _header, headers ->
        headers
    end)
  end

  defp map_into_key_value_list(:v0_execute, headers) do
    Enum.reduce(headers, [], fn
      {:allow_capabilities, capabilities}, headers ->
        [
          %Types.KeyValue{code: 0xFF04, value: <<process_capabilities(capabilities)::uint64>>}
          | headers
        ]

      _header, headers ->
        headers
    end)
  end

  defp map_into_key_value_list(_message, _headers) do
    []
  end

  defp key_value_list_into_map(:error_response, headers) do
    Enum.reduce(headers, %{}, fn
      %{code: 0x0001, value: value}, headers ->
        Map.put(headers, :hint, value)

      %{code: 0x0002, value: value}, headers ->
        Map.put(headers, :details, value)

      %{code: 0x0101, value: value}, headers ->
        Map.put(headers, :server_traceback, value)

      %{code: 0xFFF1, value: value}, headers ->
        Map.put(headers, :position_start, value)

      %{code: 0xFFF2, value: value}, headers ->
        Map.put(headers, :position_end, value)

      %{code: 0xFFF3, value: value}, headers ->
        Map.put(headers, :line_start, value)

      %{code: 0xFFF4, value: value}, headers ->
        Map.put(headers, :column_start, value)

      %{code: 0xFFF5, value: value}, headers ->
        Map.put(headers, :utf16_column_start, value)

      %{code: 0xFFF6, value: value}, headers ->
        Map.put(headers, :line_end, value)

      %{code: 0xFFF7, value: value}, headers ->
        Map.put(headers, :column_end, value)

      %{code: 0xFFF8, value: value}, headers ->
        Map.put(headers, :utf16_column_end, value)

      %{code: 0xFFF9, value: value}, headers ->
        Map.put(headers, :character_start, value)

      %{code: 0xFFFA, value: value}, headers ->
        Map.put(headers, :character_end, value)

      _header, headers ->
        headers
    end)
  end

  defp key_value_list_into_map(:v0_command_complete, headers) do
    Enum.reduce(headers, %{}, fn
      %{code: 0x1001, value: <<capabilities::uint64>>}, headers ->
        Map.put(headers, :capabilities, process_capabilities(capabilities))

      _header, headers ->
        headers
    end)
  end

  defp key_value_list_into_map(:v0_prepare_complete, headers) do
    Enum.reduce(headers, %{}, fn
      %{code: 0x1001, value: <<capabilities::uint64>>}, headers ->
        Map.put(headers, :capabilities, process_capabilities(capabilities))

      _header, headers ->
        headers
    end)
  end

  defp key_value_list_into_map(_message, _headers) do
    %{}
  end

  defp map_into_annotation_list(annotations) when is_map(annotations) do
    Enum.map(annotations, fn {name, value} ->
      %Types.Annotation{name: name, value: @json_library.encode!(value)}
    end)
  end

  defp annotation_list_into_map(annotations) when is_list(annotations) do
    Enum.into(annotations, %{}, fn %Types.Annotation{name: name, value: value} ->
      {name, @json_library.decode!(value)}
    end)
  end

  defp encode_enum(:output_format, :binary) do
    0x62
  end

  defp encode_enum(:output_format, :json) do
    0x6A
  end

  defp encode_enum(:output_format, :json_elements) do
    0x4A
  end

  defp encode_enum(:output_format, :none) do
    0x6E
  end

  defp encode_enum(:cardinality, :no_result) do
    0x6E
  end

  defp encode_enum(:cardinality, :at_most_one) do
    0x6F
  end

  defp encode_enum(:cardinality, :one) do
    0x41
  end

  defp encode_enum(:cardinality, :many) do
    0x6D
  end

  defp encode_enum(:cardinality, :at_least_one) do
    0x4D
  end

  defp encode_enum(:describe_aspect, :data_description) do
    0x54
  end

  defp decode_enum(:error_severity, 0x78) do
    :error
  end

  defp decode_enum(:error_severity, 0xC8) do
    :fatal
  end

  defp decode_enum(:error_severity, 0xFF) do
    :panic
  end

  defp decode_enum(:message_severity, 0x14) do
    :debug
  end

  defp decode_enum(:message_severity, 0x28) do
    :info
  end

  defp decode_enum(:message_severity, 0x3C) do
    :notice
  end

  defp decode_enum(:message_severity, 0x50) do
    :warning
  end

  defp decode_enum(:cardinality, 0x6E) do
    :no_result
  end

  defp decode_enum(:cardinality, 0x6F) do
    :at_most_one
  end

  defp decode_enum(:cardinality, 0x41) do
    :one
  end

  defp decode_enum(:cardinality, 0x6D) do
    :many
  end

  defp decode_enum(:cardinality, 0x4D) do
    :at_least_one
  end

  defp decode_enum(:transaction_state, 0x49) do
    :not_in_transaction
  end

  defp decode_enum(:transaction_state, 0x54) do
    :in_transaction
  end

  defp decode_enum(:transaction_state, 0x45) do
    :in_failed_transaction
  end

  defp process_capabilities(capability) when is_atom(capability) do
    process_capabilities([capability])
  end

  defp process_capabilities([]) do
    0x0
  end

  defp process_capabilities(capabilites) when is_list(capabilites) do
    atoms = %{
      readonly: 0x0,
      modifications: 0x1,
      session_config: 0x2,
      transaction: 0x4,
      ddl: 0x8,
      persistent_config: 0x10,
      execute: 0xFFFFFFFFFFFFFFF9,
      legacy_execute: 0xFFFFFFFFFFFFFFFB,
      all: 0xFFFFFFFFFFFFFFFF
    }

    capabilites
    |> Enum.map(&atoms[&1])
    |> Enum.reduce(0, &Bitwise.bor(&1, &2))
  end

  defp process_capabilities(0x0) do
    [:readonly]
  end

  defp process_capabilities(capabilities) do
    codes = %{
      0x0 => :readonly,
      0x1 => :modifications,
      0x2 => :session_config,
      0x4 => :transaction,
      0x8 => :ddl,
      0x10 => :persistent_config,
      0xFFFFFFFFFFFFFFF9 => :execute,
      0xFFFFFFFFFFFFFFFB => :legacy_execute,
      0xFFFFFFFFFFFFFFFF => :all
    }

    codes
    |> Map.keys()
    |> Enum.map(fn code ->
      if Bitwise.band(capabilities, code) != 0 do
        codes[code]
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil(&1))
  end

  defp process_compilation_flags(compilation_flag) when is_atom(compilation_flag) do
    process_compilation_flags([compilation_flag])
  end

  defp process_compilation_flags([]) do
    0x0
  end

  defp process_compilation_flags(compilation_flags) when is_list(compilation_flags) do
    atoms = %{
      inject_output_type_ids: 0x1,
      inject_output_type_names: 0x2,
      inject_output_object_ids: 0x4
    }

    compilation_flags
    |> Enum.map(&atoms[&1])
    |> Enum.reduce(0, &Bitwise.bor(&1, &2))
  end
end
