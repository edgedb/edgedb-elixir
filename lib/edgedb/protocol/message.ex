defmodule EdgeDB.Protocol.Message do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  @callback encode_message(term()) :: iodata()
  @callback decode_message(bitstring()) :: term()
  @optional_callbacks encode_message: 1, decode_message: 1

  defmacro __using__(_opts \\ []) do
    quote do
      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)
    end
  end

  defmacro defmessage(opts) do
    fields = Keyword.get(opts, :fields, [])
    struct_def = EdgeDB.Protocol.Utils.define_struct(fields)

    mtype = Keyword.fetch!(opts, :mtype)
    mtype_access_fun_def = define_mtype_access_fun(mtype)

    define_client_message? = Keyword.get(opts, :client, false)
    define_server_message? = Keyword.get(opts, :server, false)

    encoder_def = define_message_encoder(mtype, fields)
    decoder_def = define_message_decoder(mtype)

    known_headers = opts[:known_headers]
    {known_headers, _bindings} = Code.eval_quoted(known_headers, [], __CALLER__)
    known_headers = known_headers || %{}
    known_headers_typespec = define_known_headers_typespec(known_headers)
    headers_encoder_def = define_headers_encoder(known_headers)
    headers_decoder_def = define_headers_decoder(known_headers)

    quote do
      @behaviour unquote(__MODULE__)

      unquote(known_headers_typespec)
      unquote(struct_def)
      unquote(mtype_access_fun_def)

      if unquote(define_client_message?) do
        unquote(encoder_def)
        unquote(headers_encoder_def)
      end

      if unquote(define_server_message?) do
        unquote(decoder_def)
        unquote(headers_decoder_def)
      end
    end
  end

  @spec encode((tuple() -> iodata()), integer(), struct()) :: iodata()
  def encode(encoder, mtype, message) do
    message_payload = encoder.(message)
    payload_length = IO.iodata_length(message_payload) + 4

    [
      Datatypes.UInt8.encode(mtype),
      Datatypes.UInt32.encode(payload_length),
      message_payload
    ]
  end

  @spec decode(
          (bitstring() -> tuple()),
          integer(),
          bitstring()
        ) :: {:ok, {struct(), bitstring()}} | {:error, {:not_enough_size, integer()}}

  def decode(_decoder, _mtype, <<data::binary>>) when byte_size(data) < 5 do
    {:error, {:not_enough_size, 0}}
  end

  def decode(decoder, mtype, <<mtype::uint8, message_length::uint32, rest::binary>>) do
    payload_length = message_length - 4

    case rest do
      <<message_payload::binary(payload_length), rest::binary>> ->
        {:ok, {decoder.(message_payload), rest}}

      _payload ->
        {:error, {:not_enough_size, payload_length - byte_size(rest)}}
    end
  end

  defp define_mtype_access_fun(mtype) do
    quote do
      @spec mtype() :: integer()
      def mtype do
        unquote(mtype)
      end
    end
  end

  defp define_message_encoder(mtype, fields) do
    has_fields? = length(fields) != 0

    quote do
      @spec encode(t()) :: iodata()
      def encode(%__MODULE__{} = message) do
        unquote(__MODULE__).encode(&__MODULE__.encode_message/1, unquote(mtype), message)
      end

      if not unquote(has_fields?) do
        @impl EdgeDB.Protocol.Message
        def encode_message(%__MODULE__{}) do
          []
        end
      end
    end
  end

  defp define_message_decoder(mtype) do
    quote do
      @spec decode(bitstring()) ::
              {:ok, {t(), bitstring()}} | {:error, {:not_enough_size, non_neg_integer()}}
      def decode(<<data::binary>>) do
        unquote(__MODULE__).decode(&decode_message/1, unquote(mtype), data)
      end
    end
  end

  defp define_known_headers_typespec(known_headers) when map_size(known_headers) == 0 do
    quote do
      @type known_header() :: atom()
    end
  end

  defp define_known_headers_typespec(known_headers) do
    main_spec =
      known_headers
      |> Map.keys()
      |> Enum.reduce(nil, fn
        header, nil ->
          quote do
            unquote(header)
          end

        header, acc ->
          quote do
            unquote(acc) | unquote(header)
          end
      end)

    quote do
      @type known_header() :: unquote(main_spec)
    end
  end

  defp define_headers_encoder(known_headers) when map_size(known_headers) == 0 do
    quote do
      @spec handle_headers(%{required(known_header()) => term()}) ::
              list(EdgeDB.Protocol.Types.Header.t())
      def handle_headers(_headers) do
        []
      end
    end
  end

  defp define_headers_encoder(known_headers) do
    known_names = Map.keys(known_headers)

    main_handler =
      quote do
        @spec handle_headers(%{required(known_header()) => term()}) ::
                list(EdgeDB.Protocol.Types.Header.t())
        def handle_headers(headers) do
          for {header, value} <- headers, header in unquote(known_names) do
            handle_header(header, value)
          end
        end
      end

    handlers =
      for {header, opts} <- known_headers do
        code = opts[:code]
        encoder = opts[:encoder]

        do_encode =
          case encoder do
            nil ->
              quote do
                value
              end

            encoder when is_function(encoder) ->
              quote do
                unquote(encoder).(value)
              end

            encoder ->
              quote do
                unquote(encoder).encode(value)
              end
          end

        quote do
          defp handle_header(unquote(header), value) do
            %Types.Header{code: unquote(code), value: unquote(do_encode)}
          end
        end
      end

    [main_handler | handlers]
  end

  defp define_headers_decoder(known_headers) when map_size(known_headers) == 0 do
    quote do
      @spec handle_headers(list(EdgeDB.Protocol.Types.Header.t())) :: %{
              required(known_header()) => term()
            }
      def handle_headers(_headers) do
        %{}
      end
    end
  end

  defp define_headers_decoder(known_headers) do
    known_codes =
      Enum.map(known_headers, fn {_name, opts} ->
        opts[:code]
      end)

    main_handler =
      quote do
        @spec handle_headers(list(EdgeDB.Protocol.Types.Header.t())) :: %{
                required(known_header()) => term()
              }
        def handle_headers(headers) do
          for %Types.Header{code: code, value: value} <- headers,
              code in unquote(known_codes),
              into: %{} do
            handle_header(code, value)
          end
        end
      end

    handlers =
      for {header, opts} <- known_headers do
        code = opts[:code]
        decoder = opts[:decoder]

        do_decode =
          case decoder do
            nil ->
              quote do
                value
              end

            decoder when is_function(decoder) ->
              quote do
                unquote(decoder).(value)
              end

            decoder ->
              quote do
                unquote(decoder).decode(value)
              end
          end

        quote do
          defp handle_header(unquote(code), value) do
            {unquote(header), unquote(do_decode)}
          end
        end
      end

    [main_handler | handlers]
  end
end
