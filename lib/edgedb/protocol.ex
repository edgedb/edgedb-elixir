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

  @type client_message() ::
          Client.AuthenticationSASLInitialResponse.t()
          | Client.AuthenticationSASLResponse.t()
          | Client.ClientHandshake.t()
          | Client.DescribeStatement.t()
          | Client.ExecuteScript.t()
          | Client.Execute.t()
          | Client.Flush.t()
          | Client.OptimisticExecute.t()
          | Client.Prepare.t()
          | Client.Sync.t()
          | Client.Terminate.t()

  @type server_message() ::
          Server.AuthenticationOK.t()
          | Server.AuthenticationSASL.t()
          | Server.AuthenticationSASLContinue.t()
          | Server.AuthenticationSASLFinal.t()
          | Server.CommandComplete.t()
          | Server.CommandDataDescription.t()
          | Server.Data.t()
          | Server.ErrorResponse.t()
          | Server.LogMessage.t()
          | Server.ParameterStatus.t()
          | Server.PrepareComplete.t()
          | Server.ReadyForCommand.t()
          | Server.ServerHandshake.t()
          | Server.ServerKeyData.t()

  @message_header_length 5

  @spec message_header_length() :: unquote(@message_header_length)
  def message_header_length do
    @message_header_length
  end

  @spec parse_message_header(bitstring()) :: {message_code(), non_neg_integer()}
  def parse_message_header(<<type::uint8, payload_length::int32>>) do
    {type, payload_length - 4}
  end

  @spec encode_message(client_message()) :: iodata()
  def encode_message(message) do
    {type, payload} = do_message_encoding(message)

    [
      type,
      <<IO.iodata_length(payload) + 4::int32>>,
      payload
    ]
  end

  @spec decode_message(message_code(), bitstring()) :: server_message()
  def decode_message(type, payload) do
    do_message_decoding(type, payload)
  end

  @spec parse_type_description(bitstring(), CodecStorage.t()) :: Codec.id()
  def parse_type_description(type_description, codec_storage) do
    do_type_description_parsing(type_description, codec_storage, %{})
  end

  @spec decode_system_config(bitstring()) :: Types.ParameterStatus.SystemConfig.t()
  def decode_system_config(system_config) do
    do_system_config_decoding(system_config)
  end

  defp do_message_encoding(%Client.ExecuteScript{} = message) do
    headers = map_into_headers(:execute_script, message.headers)

    {0x51,
     [
       encode_header_list(headers),
       <<byte_size(message.script)::uint32>>,
       message.script
     ]}
  end

  defp do_message_encoding(%Client.Prepare{} = message) do
    headers = map_into_headers(:prepare, message.headers)

    {0x50,
     [
       encode_header_list(headers),
       encode_enum(:io_format, message.io_format),
       encode_enum(:cardinality, message.expected_cardinality),
       <<0::uint32>>,
       <<byte_size(message.command)::uint32>>,
       message.command
     ]}
  end

  defp do_message_encoding(%Client.DescribeStatement{} = message) do
    headers = map_into_headers(:describe_statement, message.headers)

    {0x44,
     [
       encode_header_list(headers),
       encode_enum(:describe_aspect, message.aspect),
       <<0::uint32>>
     ]}
  end

  defp do_message_encoding(%Client.Sync{}) do
    {0x53, []}
  end

  defp do_message_encoding(%Client.Flush{}) do
    {0x48, []}
  end

  defp do_message_encoding(%Client.Execute{} = message) do
    headers = map_into_headers(:execute, message.headers)

    {0x45,
     [
       encode_header_list(headers),
       <<0::uint32>>,
       message.arguments
     ]}
  end

  defp do_message_encoding(%Client.OptimisticExecute{} = message) do
    headers = map_into_headers(:optimisitc_execute, message.headers)

    {0x4F,
     [
       encode_header_list(headers),
       encode_enum(:io_format, message.io_format),
       encode_enum(:cardinality, message.expected_cardinality),
       <<byte_size(message.command_text)::uint32>>,
       message.command_text,
       message.input_typedesc_id,
       message.output_typedesc_id,
       message.arguments
     ]}
  end

  defp do_message_encoding(%Client.ClientHandshake{} = message) do
    {0x56,
     [
       <<message.major_ver::uint16, message.minor_ver::uint16>>,
       encode_connection_param_list(message.params),
       encode_extension_list(message.extensions)
     ]}
  end

  defp do_message_encoding(%Client.AuthenticationSASLInitialResponse{} = message) do
    {0x70,
     [
       <<byte_size(message.method)::uint32>>,
       message.method,
       <<byte_size(message.sasl_data)::uint32>>,
       message.sasl_data
     ]}
  end

  defp do_message_encoding(%Client.AuthenticationSASLResponse{} = message) do
    {0x72,
     [
       <<byte_size(message.sasl_data)::uint32>>,
       message.sasl_data
     ]}
  end

  defp do_message_encoding(%Client.Terminate{}) do
    {0x58, []}
  end

  defp do_message_decoding(0x45, <<severity::uint8, error_code::uint32, rest::binary>>) do
    <<message_size::uint32, message::binary(message_size), rest::binary>> = rest
    {attributes, <<>>} = decode_header_list(rest)

    %Server.ErrorResponse{
      error_code: error_code,
      severity: decode_enum(:error_severity, severity),
      message: message,
      attributes: headers_into_map(:error_response, attributes)
    }
  end

  defp do_message_decoding(0x4C, <<severity::uint8, code::uint32, rest::binary>>) do
    <<text_size::uint32, text::binary(text_size), rest::binary>> = rest
    {attributes, <<>>} = decode_header_list(rest)

    %Server.LogMessage{
      code: code,
      severity: decode_enum(:message_severity, severity),
      text: text,
      attributes: attributes
    }
  end

  defp do_message_decoding(0x5A, <<data::binary>>) do
    {headers, <<transaction_state::uint8>>} = decode_header_list(data)

    %Server.ReadyForCommand{
      headers: headers,
      transaction_state: decode_enum(:transaction_state, transaction_state)
    }
  end

  defp do_message_decoding(0x43, <<data::binary>>) do
    {headers, <<status_size::uint32, status::binary(status_size)>>} = decode_header_list(data)

    %Server.CommandComplete{
      headers: headers_into_map(:command_complete, headers),
      status: status
    }
  end

  defp do_message_decoding(0x54, <<data::binary>>) do
    {headers,
     <<
       result_cardinality::uint8,
       input_typedesc_id::uuid,
       input_typedesc_size::uint32,
       input_typedesc::binary(input_typedesc_size),
       output_typedesc_id::uuid,
       output_typedesc_size::uint32,
       output_typedesc::binary(output_typedesc_size)
     >>} = decode_header_list(data)

    %Server.CommandDataDescription{
      headers: headers_into_map(:command_data_description, headers),
      result_cardinality: decode_enum(:cardinality, result_cardinality),
      input_typedesc_id: input_typedesc_id,
      input_typedesc: input_typedesc,
      output_typedesc_id: output_typedesc_id,
      output_typedesc: output_typedesc
    }
  end

  defp do_message_decoding(0x44, <<data::binary>>) do
    {data, <<>>} = decode_data_element_list(data)
    %Server.Data{data: data}
  end

  defp do_message_decoding(0x4B, <<data::binary(32)>>) do
    %Server.ServerKeyData{data: data}
  end

  defp do_message_decoding(
         0x53,
         <<
           name_size::uint32,
           name::binary(name_size),
           value_size::uint32,
           value::binary(value_size)
         >>
       ) do
    %Server.ParameterStatus{name: name, value: value}
  end

  defp do_message_decoding(0x31, <<data::binary>>) do
    {headers,
     <<
       cardinality::uint8,
       input_typedesc_id::uuid,
       output_typedesc_id::uuid
     >>} = decode_header_list(data)

    %Server.PrepareComplete{
      headers: headers_into_map(:prepare_complete, headers),
      cardinality: decode_enum(:cardinality, cardinality),
      input_typedesc_id: input_typedesc_id,
      output_typedesc_id: output_typedesc_id
    }
  end

  defp do_message_decoding(0x76, <<major_ver::uint16, minor_ver::uint16, rest::binary>>) do
    {extensions, <<>>} = decode_extension_list(rest)

    %Server.ServerHandshake{
      major_ver: major_ver,
      minor_ver: minor_ver,
      extensions: extensions
    }
  end

  defp do_message_decoding(0x52, <<auth_status::uint32>>) do
    %Server.AuthenticationOK{auth_status: auth_status}
  end

  defp do_message_decoding(0x52, <<0xA::uint32, num_methods::uint32, rest::binary>>) do
    {methods, <<>>} = decode_string_list(rest, num_methods, [])
    %Server.AuthenticationSASL{auth_status: 0xA, methods: methods}
  end

  defp do_message_decoding(
         0x52,
         <<0xB::uint32, sasl_data_size::uint32, sasl_data::binary(sasl_data_size)>>
       ) do
    %Server.AuthenticationSASLContinue{auth_status: 0xB, sasl_data: sasl_data}
  end

  defp do_message_decoding(
         0x52,
         <<0xC::uint32, sasl_data_size::uint32, sasl_data::binary(sasl_data_size)>>
       ) do
    %Server.AuthenticationSASLFinal{auth_status: 0xB, sasl_data: sasl_data}
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
        Codecs.Object.new(id, shape_elements, codecs)
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

  defp encode_header_list(headers) do
    data =
      for header <- headers do
        [<<header.code::uint16, byte_size(header.value)::uint32>>, header.value]
      end

    [<<length(headers)::uint16>> | data]
  end

  defp decode_header_list(<<num_headers::uint16, data::binary>>) do
    decode_header_list(data, num_headers, [])
  end

  defp decode_header_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_header_list(<<data::binary>>, count, acc) do
    <<code::uint16, value_size::uint32, value::binary(value_size), rest::binary>> = data
    decode_header_list(rest, count - 1, [%Types.Header{code: code, value: value} | acc])
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
        [
          <<byte_size(extension.name)::uint32>>,
          extension.name,
          encode_header_list(extension.headers)
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
    {headers, rest} = decode_header_list(rest)

    decode_data_element_list(rest, count - 1, [
      %Types.ProtocolExtension{name: name, headers: headers} | acc
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

  defp map_into_headers(:execute_script, headers) do
    Enum.reduce(headers, [], fn
      {:allow_capabilities, capabilities}, headers ->
        [
          %Types.Header{code: 0xFF04, value: <<process_capabilities(capabilities)::uint64>>}
          | headers
        ]

      _header, headers ->
        headers
    end)
  end

  defp map_into_headers(:optimisitc_execute, headers) do
    Enum.reduce(headers, [], fn
      {:implicit_limit, value}, headers ->
        [%Types.Header{code: 0xFF01, value: value} | headers]

      {:implicit_typenames, value}, headers ->
        [%Types.Header{code: 0xFF02, value: value} | headers]

      {:implicit_typeids, value}, headers ->
        [%Types.Header{code: 0xFF03, value: value} | headers]

      {:allow_capabilities, capabilities}, headers ->
        [
          %Types.Header{code: 0xFF04, value: <<process_capabilities(capabilities)::uint64>>}
          | headers
        ]

      {:explicit_objectids, value}, headers ->
        [%Types.Header{code: 0xFF05, value: value} | headers]

      _header, headers ->
        headers
    end)
  end

  defp map_into_headers(:execute, headers) do
    Enum.reduce(headers, [], fn
      {:allow_capabilities, capabilities}, headers ->
        [
          %Types.Header{code: 0xFF04, value: <<process_capabilities(capabilities)::uint64>>}
          | headers
        ]

      _header, headers ->
        headers
    end)
  end

  defp map_into_headers(_message, _headers) do
    []
  end

  defp headers_into_map(:error_response, headers) do
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

  defp headers_into_map(:command_complete, headers) do
    Enum.reduce(headers, %{}, fn
      %{code: 0x1001, value: <<capabilities::uint64>>}, headers ->
        Map.put(headers, :capabilities, process_capabilities(capabilities))

      _header, headers ->
        headers
    end)
  end

  defp headers_into_map(:prepare_complete, headers) do
    Enum.reduce(headers, %{}, fn
      %{code: 0x1001, value: <<capabilities::uint64>>}, headers ->
        Map.put(headers, :capabilities, process_capabilities(capabilities))

      _header, headers ->
        headers
    end)
  end

  defp headers_into_map(_message, _headers) do
    %{}
  end

  defp encode_enum(:io_format, :binary) do
    0x62
  end

  defp encode_enum(:io_format, :json) do
    0x6A
  end

  defp encode_enum(:io_format, :json_elements) do
    0x4A
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

  defp process_capabilities(capabilities) when is_atom(capabilities) do
    process_capabilities([capabilities])
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
      persistent_config: 0x10
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
      0x10 => :persistent_config
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
end
