defmodule EdgeDB.Protocol.TypeDescriptor do
  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    Datatypes
  }

  @callback parse_description(
              codecs :: list(Codec.t()),
              type_id :: Datatypes.UUID.t(),
              data :: bitstring()
            ) :: {term(), bitstring()}
  @callback consume_description(
              storage :: Codecs.Storage.t(),
              type_id :: Datatypes.UUID.t(),
              data :: bitstring()
            ) :: bitstring()
  @optional_callbacks parse_description: 3, consume_description: 3

  defmacro __using__(_opts \\ []) do
    quote do
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)
    end
  end

  defmacro deftypedescriptor(opts \\ []) do
    type = Keyword.fetch!(opts, :type)
    type_access_fun_def = define_type_access_fun(type)

    define_parser? = Keyword.get(opts, :parse, true)
    define_consumer? = Keyword.get(opts, :consume, true)

    support_funs_def = define_support_funs(define_parser?, define_consumer?)

    parser_def = define_typedescriptor_parser(type)
    consumer_def = define_typedescriptor_consumer(type)

    quote do
      @behaviour unquote(__MODULE__)

      unquote(type_access_fun_def)
      unquote(support_funs_def)

      if unquote(define_parser?) do
        unquote(parser_def)
      end

      if unquote(define_consumer?) do
        unquote(consumer_def)
      end
    end
  end

  defp define_type_access_fun(type) do
    quote do
      @spec type() :: term()
      def type do
        unquote(type)
      end
    end
  end

  defp define_support_funs(support_parsing, support_consuming) do
    quote do
      @spec support_parsing?() :: boolean()
      def support_parsing? do
        unquote(support_parsing)
      end

      @spec support_consuming?() :: boolean()
      def support_consuming? do
        unquote(support_consuming)
      end
    end
  end

  defp define_typedescriptor_parser(type) do
    quote do
      @spec parse(list(EdgeDB.Protocol.Codec.t()), bitstring()) ::
              {EdgeDB.Protocol.Codec.t(), bitstring()}
      def parse(
            codecs,
            <<
              unquote(type)::uint8,
              type_id::uuid,
              rest::binary
            >> = type_description
          ) do
        parse_description(codecs, EdgeDB.Protocol.Datatypes.UUID.to_string(type_id), rest)
      end
    end
  end

  defp define_typedescriptor_consumer(type) do
    quote do
      @spec consume(EdgeDB.Protocol.Codecs.Storage.t(), bitstring()) :: bitstring()
      def consume(
            storage,
            <<
              unquote(type)::uint8,
              type_id::uuid,
              rest::binary
            >> = type_description
          ) do
        consume_description(storage, EdgeDB.Protocol.Datatypes.UUID.to_string(type_id), rest)
      end
    end
  end

  @spec codec_by_index(list(EdgeDB.Protocol.Codec.t()), pos_integer()) ::
          EdgeDB.Protocol.Codec.t() | nil
  def codec_by_index(codecs, index) do
    Enum.at(codecs, length(codecs) - index - 1)
  end
end
