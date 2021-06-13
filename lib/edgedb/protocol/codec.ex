defmodule EdgeDB.Protocol.Codec do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Datatypes,
    Error
  }

  @callback encode_instance(term()) :: iodata()
  @callback decode_instance(bitstring()) :: term()

  defstruct [
    :type_id,
    :type_name,
    :encoder,
    :decoder,
    :module,
    parent: nil,
    scalar?: false
  ]

  @type t() :: %__MODULE__{
          type_id: Datatypes.UUID.t() | nil,
          type_name: String.t() | nil,
          encoder: (t(), term() -> iodata()),
          decoder: (t(), bitstring() -> term()),
          module: atom(),
          parent: atom() | nil,
          scalar?: boolean()
        }

  defmacro __using__(_opts \\ []) do
    quote do
      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__),
        only: [
          defcodec: 0,
          defcodec: 1,
          defbasescalarcodec: 0,
          defbasescalarcodec: 1
        ]

      alias unquote(__MODULE__)
    end
  end

  defmacro defcodec(opts \\ []) do
    type = Keyword.fetch!(opts, :type)
    calculate_size? = Keyword.get(opts, :calculate_size?, true)

    quote do
      @type t() :: unquote(type)

      @spec create_encoder((t() -> iodata())) :: (unquote(__MODULE__).t(), t() -> iodata())
      def create_encoder(encoder) do
        unquote(__MODULE__).create_encoder(encoder, unquote(calculate_size?))
      end

      @spec create_decoder((bitstring() -> t())) :: (unquote(__MODULE__).t(), bitstring() -> t())
      def create_decoder(decoder) do
        unquote(__MODULE__).create_decoder(decoder, unquote(calculate_size?))
      end
    end
  end

  defmacro defbasescalarcodec(opts \\ []) do
    calculate_size? = Keyword.get(opts, :calculate_size?, true)
    type_name = Keyword.get(opts, :type_name)
    type_id = Keyword.fetch!(opts, :type_id)
    type = Keyword.fetch!(opts, :type)

    quote do
      @behaviour unquote(__MODULE__)

      @type t() :: unquote(type)

      @type_name unquote(type_name)
      @type_id unquote(type_id)

      @spec new() :: unquote(__MODULE__).t()
      def new do
        encoder =
          unquote(__MODULE__).create_encoder(
            &__MODULE__.encode_instance/1,
            unquote(calculate_size?)
          )

        decoder =
          unquote(__MODULE__).create_decoder(
            &__MODULE__.decode_instance/1,
            unquote(calculate_size?)
          )

        %unquote(__MODULE__){
          type_id: @type_id,
          type_name: @type_name,
          encoder: encoder,
          decoder: decoder,
          module: __MODULE__,
          scalar?: true
        }
      end
    end
  end

  defmacrop wrap_codec_operation(codec, operation, exception_creation_callback, base_message) do
    quote do
      try do
        unquote(operation)
      rescue
        _exc in FunctionClauseError ->
          error =
            if type_name = unquote(codec).type_name do
              "#{unquote(base_message)} as #{type_name}"
            else
              unquote(base_message)
            end

          reraise unquote(exception_creation_callback).(error), __STACKTRACE__
      end
    end
  end

  @spec encode(t(), term()) :: iodata()
  def encode(%__MODULE__{encoder: encoder} = codec, instance) do
    encoder.(codec, instance)
  end

  @spec decode(t(), bitstring()) :: term()
  def decode(%__MODULE__{decoder: decoder} = codec, <<data::binary>>) do
    decoder.(codec, data)
  end

  @spec create_encoder((term() -> iodata()), boolean()) :: (t(), term() -> iodata())
  def create_encoder(encoder, calculate_size?) do
    fn codec, instance ->
      encoded_data =
        wrap_codec_operation(
          codec,
          encoder.(instance),
          &Error.invalid_argument_error/1,
          "unable to encode #{inspect(instance)}"
        )

      if calculate_size? do
        instance_size = IO.iodata_length(encoded_data)

        [
          Datatypes.UInt32.encode(instance_size),
          encoded_data
        ]
      else
        encoded_data
      end
    end
  end

  @spec create_decoder((bitstring() -> term()), boolean()) :: (t(), bitstring() -> term())
  def create_decoder(decoder, calculate_size?) do
    if calculate_size? do
      fn codec, <<size::uint32, data::binary(size)>> ->
        wrap_codec_operation(
          codec,
          decoder.(data),
          &Error.invalid_argument_error/1,
          "unable to decode binary data"
        )
      end
    else
      fn codec, <<data::binary>> ->
        wrap_codec_operation(
          codec,
          decoder.(data),
          &Error.invalid_argument_error/1,
          "unable to decode binary data"
        )
      end
    end
  end
end
