defmodule EdgeDB.Protocol.Codec do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.Datatypes

  @callback encode_instance(term()) :: iodata()
  @callback decode_instance(bitstring()) :: term()

  defstruct [
    :type_id,
    :type_name,
    :encoder,
    :decoder,
    :module,
    :parent,
    is_scalar: false
  ]

  @type t() :: %__MODULE__{
          type_id: Datatypes.UUID.t() | nil,
          type_name: String.t() | nil,
          encoder: (t(), term() -> iodata()),
          decoder: (t(), bitstring() -> term()),
          module: module(),
          parent: module() | nil,
          is_scalar: boolean()
        }

  defmacro __using__(_opts \\ []) do
    quote do
      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__),
        only: [
          defcodec: 1,
          defscalarcodec: 1,
          defbuiltinscalarcodec: 1,
          defbasescalarcodec: 1
        ]

      alias unquote(__MODULE__)
    end
  end

  defmacro defcodec(opts) do
    type = Keyword.fetch!(opts, :type)
    typespec_def = define_typespec(type)

    calculate_size? = Keyword.get(opts, :calculate_size, true)
    encoder_def = define_encoder(calculate_size?)
    decoder_def = define_decoder(calculate_size?)

    quote do
      unquote(typespec_def)
      unquote(encoder_def)
      unquote(decoder_def)
    end
  end

  defmacro defbasescalarcodec(opts) do
    type = Keyword.fetch!(opts, :type)
    typespec_def = define_typespec(type)

    type_id = Keyword.get(opts, :type_id)
    type_id_access_fun_def = define_type_id_access_fun(type_id)

    type_name = Keyword.get(opts, :type_name)
    type_name_access_fun_def = define_type_name_access_fun(type_name)

    calculate_size? = Keyword.get(opts, :calculate_size, true)
    constructor_def = define_codec_constuctor(type_id, type_name, calculate_size?)

    quote do
      @behaviour unquote(__MODULE__)

      unquote(typespec_def)
      unquote(type_id_access_fun_def)
      unquote(type_name_access_fun_def)
      unquote(constructor_def)

      defoverridable new: 0
    end
  end

  defmacro defscalarcodec(opts) do
    # ensure required opts present in declaration since it's macros for custom codecs
    # which type_ids will fetched by names
    _type_name = Keyword.fetch!(opts, :type_name)

    quote do
      defbasescalarcodec(unquote(opts))
    end
  end

  defmacro defbuiltinscalarcodec(opts) do
    # ensure required opts present in declaration since it's macros for builtin codecs
    _type = Keyword.fetch!(opts, :type)
    _type_id = Keyword.fetch!(opts, :type_id)

    quote do
      defbasescalarcodec(unquote(opts))
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
    if calculate_size? do
      fn codec, instance ->
        encoded_data =
          wrap_codec_operation(
            codec,
            encoder.(instance),
            &EdgeDB.Error.invalid_argument_error/1,
            "unable to encode #{inspect(instance)}"
          )

        instance_size = IO.iodata_length(encoded_data)

        [
          Datatypes.UInt32.encode(instance_size),
          encoded_data
        ]
      end
    else
      fn codec, instance ->
        wrap_codec_operation(
          codec,
          encoder.(instance),
          &EdgeDB.Error.invalid_argument_error/1,
          "unable to encode #{inspect(instance)}"
        )
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
          &EdgeDB.Error.invalid_argument_error/1,
          "unable to decode binary data"
        )
      end
    else
      fn codec, <<data::binary>> ->
        wrap_codec_operation(
          codec,
          decoder.(data),
          &EdgeDB.Error.invalid_argument_error/1,
          "unable to decode binary data"
        )
      end
    end
  end

  defp define_typespec(type) do
    quote do
      @type t() :: unquote(type)
    end
  end

  defp define_encoder(calculate_size) do
    quote do
      @spec create_encoder((t() -> iodata())) :: (unquote(__MODULE__).t(), t() -> iodata())
      def create_encoder(encoder) do
        unquote(__MODULE__).create_encoder(encoder, unquote(calculate_size))
      end
    end
  end

  defp define_decoder(calculate_size) do
    quote do
      @spec create_decoder((bitstring() -> t())) :: (unquote(__MODULE__).t(), bitstring() -> t())
      def create_decoder(decoder) do
        unquote(__MODULE__).create_decoder(decoder, unquote(calculate_size))
      end
    end
  end

  defp define_type_id_access_fun(type_id) do
    quote do
      @spec type_id() :: EdgeDB.Protocol.Datatypes.UUID.t() | nil
      def type_id do
        unquote(type_id)
      end
    end
  end

  defp define_type_name_access_fun(type_name) do
    quote do
      @spec type_name() :: String.t() | nil
      def type_name do
        unquote(type_name)
      end
    end
  end

  defp define_codec_constuctor(type_id, type_name, calculate_size) do
    quote do
      @spec new() :: unquote(__MODULE__).t()
      def new do
        encoder =
          unquote(__MODULE__).create_encoder(
            &encode_instance/1,
            unquote(calculate_size)
          )

        decoder =
          unquote(__MODULE__).create_decoder(
            &decode_instance/1,
            unquote(calculate_size)
          )

        %unquote(__MODULE__){
          type_id: unquote(type_id),
          type_name: unquote(type_name),
          encoder: encoder,
          decoder: decoder,
          module: __MODULE__,
          is_scalar: true
        }
      end
    end
  end
end
