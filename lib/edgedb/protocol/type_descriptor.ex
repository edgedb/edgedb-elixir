defmodule EdgeDB.Protocol.TypeDescriptor do
  alias EdgeDB.Protocol.Codec

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

  defmacro deftypedescriptor(opts) do
    {:ok, type} = Keyword.fetch(opts, :type)

    parse? = Keyword.get(opts, :parse?, true)
    consume? = Keyword.get(opts, :consume?, true)

    quote do
      @descriptor_type unquote(type)

      @spec type() :: integer()
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
          parse_description(codecs, type_id, rest)
        end
      end

      if unquote(consume?) do
        @spec consume(Codecs.Storage.t(), bitstring()) :: bitstring()
        def consume(
              storage,
              <<@descriptor_type::uint8, type_id::uuid, rest::binary>> = type_description
            ) do
          consume_description(storage, type_id, rest)
        end
      end
    end
  end

  @spec codec_by_index(list(Codec.t()), non_neg_integer()) :: Codec.t()
  def codec_by_index(codecs, index) do
    Enum.at(codecs, length(codecs) - index - 1)
  end
end
