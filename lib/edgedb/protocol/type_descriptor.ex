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

      alias EdgeDB.Protocol.{
        Codec,
        Codecs
      }
    end
  end

  defmacro deftypedescriptor(opts \\ []) do
    type = Keyword.fetch!(opts, :type)

    parse? = Keyword.get(opts, :parse?, true)
    consume? = Keyword.get(opts, :consume?, true)

    quote do
      @behaviour unquote(__MODULE__)

      @descriptor_type unquote(type)

      @spec type() :: term()
      def type do
        @descriptor_type
      end

      @spec support_parsing?() :: boolean()
      def support_parsing? do
        unquote(parse?)
      end

      @spec support_consuming?() :: boolean()
      def support_consuming? do
        unquote(consume?)
      end

      if unquote(parse?) do
        @spec parse(list(Codec.t()), bitstring()) :: {Codec.t(), bitstring()}
        def parse(
              codecs,
              <<@descriptor_type::uint8, type_id::uuid, rest::binary>> = type_description
            ) do
          __MODULE__.parse_description(codecs, Datatypes.UUID.to_string(type_id), rest)
        end
      end

      if unquote(consume?) do
        @spec consume(Codecs.Storage.t(), bitstring()) :: bitstring()
        def consume(
              storage,
              <<@descriptor_type::uint8, type_id::uuid, rest::binary>> = type_description
            ) do
          __MODULE__.consume_description(storage, Datatypes.UUID.to_string(type_id), rest)
        end
      end
    end
  end

  @spec codec_by_index(list(Codec.t()), pos_integer()) :: Codec.t() | nil
  def codec_by_index(codecs, index) do
    Enum.at(codecs, length(codecs) - index - 1)
  end
end
