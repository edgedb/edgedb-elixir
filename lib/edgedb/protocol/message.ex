defmodule EdgeDB.Protocol.Message do
  import EdgeDB.Protocol.Converters
  import EdgeDB.Protocol.Types.Header

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  @callback encode_message(term()) :: iodata()
  @callback decode_message(bitstring()) :: term()
  @optional_callbacks encode_message: 1, decode_message: 1

  @type header_codec() :: %{
          encoder: (term() -> iodata()),
          decoder: (bitstring() -> term())
        }

  defmacro __using__(_opts \\ []) do
    quote do
      import Record

      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)

      alias EdgeDB.Protocol.Types
    end
  end

  defmacro defmessage(opts) do
    {:ok, mtype} = Keyword.fetch(opts, :mtype)
    {:ok, record_name} = Keyword.fetch(opts, :name)

    known_headers = Keyword.get(opts, :known_headers)

    declare_client? = Keyword.get(opts, :client, false)
    declare_server? = Keyword.get(opts, :server, false)

    fields = Keyword.get(opts, :fields, [])
    defaults = Keyword.get(opts, :defaults, [])

    has_fields? = length(fields) != 0

    quote do
      @behaviour unquote(__MODULE__)

      @mtype unquote(mtype)
      @record_name unquote(record_name)

      @known_headers unquote(known_headers) || %{}
      @known_headers_keys Map.keys(@known_headers)

      unquote(EdgeDB.Protocol.define_edgedb_record(record_name, fields, defaults))

      @spec mtype() :: integer()
      def mtype do
        unquote(mtype)
      end

      @spec record_name() :: unquote(record_name)
      def record_name do
        unquote(record_name)
      end

      if unquote(declare_client?) do
        @spec encode(t()) :: iodata()
        def encode(unquote(record_name)() = message) do
          unquote(__MODULE__).encode(&__MODULE__.encode_message/1, @mtype, message)
        end

        if not unquote(has_fields?) do
          @impl EdgeDB.Protocol.Message
          def encode_message(unquote(record_name)()) do
            []
          end
        end

        @spec process_passed_headers(Keyword.t()) :: list(Types.Header.t())
        def process_passed_headers(headers) do
          unquote(__MODULE__).transform_known_headers_into_records(@known_headers, headers)
        end
      end

      if unquote(declare_server?) do
        @spec decode(bitstring()) ::
                {:ok, {t(), bitstring()}} | {:error, {:not_enough_size, non_neg_integer()}}
        def decode(<<data::binary>>) do
          unquote(__MODULE__).decode(&__MODULE__.decode_message/1, @mtype, data)
        end

        @spec process_received_headers(list(Types.Header.t())) :: Keyword.t()
        def process_received_headers(headers) do
          unquote(__MODULE__).transform_records_into_known_headers(@known_headers, headers)
        end
      end
    end
  end

  @spec encode((tuple() -> iodata()), integer(), tuple()) :: iodata()
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
        ) :: {:ok, {tuple(), bitstring()}} | {:error, {:not_enough_size, integer()}}

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

  @spec transform_known_headers_into_records(map(), Keyword.t()) :: list(Types.Header.t())
  def transform_known_headers_into_records(known_headers, passed_headers) do
    headers =
      Enum.into(known_headers, %{}, fn
        {_name, {_code, _encoder}} = item ->
          item

        {name, code} ->
          {name, {code, :raw}}
      end)

    known_names = Map.keys(known_headers)

    passed_headers
    |> Enum.filter(fn {name, _value} ->
      name in known_names
    end)
    |> Enum.into([], fn {name, value} ->
      {code, codec} = Map.get(headers, name)
      value = encode_header_value(codec, value)
      header(code: code, value: value)
    end)
  end

  @spec transform_records_into_known_headers(map(), list(Types.Header.t())) :: Keyword.t()
  def transform_records_into_known_headers(known_headers, received_headers) do
    codes_to_names =
      Enum.into(known_headers, %{}, fn
        {name, {code, codec}} ->
          {code, {name, codec}}

        {name, code} ->
          {code, {name, :raw}}
      end)

    known_codes = Map.keys(codes_to_names)

    received_headers
    |> Enum.filter(fn header(code: code) ->
      code in known_codes
    end)
    |> Enum.into([], fn header(code: code, value: value) ->
      {name, codec} = Map.get(codes_to_names, code)
      {name, decode_header_value(codec, value)}
    end)
  end

  defp encode_header_value(:raw, value) do
    value
  end

  defp encode_header_value(codec, value) do
    codec.encoder.(value)
  end

  defp decode_header_value(:raw, value) do
    value
  end

  defp decode_header_value(codec, value) do
    codec.decoder.(value)
  end
end
