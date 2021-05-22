defmodule EdgeDB.Protocol.Message do
  # credo:disable-for-this-file Credo.Check.Design.AliasUsage

  defmacro __using__(_opts \\ []) do
    quote do
      import Record

      import EdgeDB.Protocol.Converters
      import EdgeDB.Protocol.Types.Header

      import unquote(__MODULE__)
    end
  end

  defmacro defmessage(opts) do
    {:ok, mtype} = Keyword.fetch(opts, :mtype)
    {:ok, record_name} = Keyword.fetch(opts, :name)

    record_fields = Keyword.get(opts, :fields, [])
    has_fields? = length(record_fields) != 0

    known_headers = Keyword.get(opts, :known_headers)

    declare_client? = Keyword.get(opts, :client, false)
    declare_server? = Keyword.get(opts, :server, false)

    defaults = Keyword.get(opts, :defaults, [])
    default_keys = Keyword.keys(defaults)

    quote do
      if unquote(known_headers) do
        @known_headers unquote(known_headers)
        @known_headers_keys Map.keys(@known_headers)
      end

      defrecord unquote(record_name),
                unquote(
                  record_fields
                  |> Keyword.drop(default_keys)
                  |> Keyword.keys()
                ) ++ unquote(defaults)

      @type t() :: record(unquote(record_name), unquote(record_fields))

      @spec mtype() :: unquote(mtype)
      def mtype do
        unquote(mtype)
      end

      @spec record_name() :: unquote(record_name)
      def record_name do
        unquote(record_name)
      end

      if unquote(declare_client?) do
        @spec encode(t()) :: bitstring()
      end

      if unquote(declare_server?) do
        @spec decode(bitstring()) ::
                {:ok, {t(), bitstring()}} | {:error, {:not_enough_size, integer()}}
      end

      if unquote(declare_client?) do
        def encode(unquote(record_name)() = message) do
          message_payload = encode_message(message)

          [
            EdgeDB.Protocol.DataTypes.UInt8.encode(unquote(mtype)),
            EdgeDB.Protocol.DataTypes.UInt32.encode(IO.iodata_length(message_payload) + 4)
            | message_payload
          ]
        end

        if not unquote(has_fields?) do
          defp encode_message(unquote(record_name)()) do
            []
          end
        end
      end

      if unquote(declare_client?) and unquote(known_headers) do
        defp process_headers(headers) do
          Enum.reduce(headers, [], &process_header/2)
        end

        defp process_header({name, value}, headers) when name in @known_headers_keys do
          {code, encoder} = encoder_by_name(name)
          value = encode_header_value(value, encoder)
          [header(code: code, value: value) | headers]
        end

        defp process_header(_header, headers) do
          headers
        end

        defp encode_header_value(value, :raw) do
          value
        end

        defp encode_header_value(value, encoder) do
          encoder.(value)
        end

        defp encoder_by_name(name) do
          case @known_headers[name] do
            {name, encoder} ->
              {name, encoder}

            name ->
              {name, :raw}
          end
        end
      end

      if unquote(declare_server?) do
        def decode(<<rest::binary>>) when byte_size(rest) < 5 do
          {:error, {:not_enough_size, 0}}
        end

        def decode(<<unquote(mtype)::uint8, message_length::uint32, rest::binary>>) do
          payload_length = message_length - 4

          case rest do
            <<message_payload::binary(payload_length), rest::binary>> ->
              {:ok, {decode_message(message_payload), rest}}

            _payload ->
              {:error, {:not_enough_size, payload_length - byte_size(rest)}}
          end
        end
      end

      if unquote(declare_server?) and unquote(known_headers) do
        defp process_headers(headers) do
          headers
          |> Enum.filter(&filter_header/1)
          |> Enum.into([], &transform_header/1)
        end

        defp filter_header(header(code: code)) do
          code in @known_headers_keys
        end

        defp transform_header(header(code: code, value: value)) do
          {name, decoder} = decoder_by_code(code)
          {name, decode_header_value(value, decoder)}
        end

        defp decode_header_value(value, :raw) do
          value
        end

        defp decode_header_value(header(code: code, value: value), decoder) do
          decoder.(value)
        end

        defp decoder_by_code(code) do
          case @known_headers[code] do
            {code, decoder} ->
              {code, decoder}

            code ->
              {code, :raw}
          end
        end
      end
    end
  end
end
