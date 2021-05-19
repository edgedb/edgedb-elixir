defmodule EdgeDB.Protocol.TypeDescriptor do
  defmacro __using__(_opts \\ []) do
    quote do
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)
    end
  end

  defmacro deftypedescriptor(opts) do
    {:ok, type} = Keyword.fetch(opts, :type)

    parse? = Keyword.get(opts, :parse?, true)
    consume? = Keyword.get(opts, :consume?, true)

    quote do
      @descriptor_type unquote(type)

      def type do
        @descriptor_type
      end

      def support_parsing? do
        unquote(parse?)
      end

      def support_consuming? do
        unquote(consume?)
      end

      if unquote(parse?) do
        def parse(
              codecs,
              <<@descriptor_type::uint8, type_id::uuid, rest::binary>> = type_description
            ) do
          parse_description(codecs, type_id, rest)
        end
      end

      if unquote(consume?) do
        def consume(
              storage,
              <<@descriptor_type::uint8, type_id::uuid, rest::binary>> = type_description
            ) do
          consume_description(storage, type_id, rest)
        end
      end
    end
  end

  def codec_by_index(codecs, index) do
    Enum.at(codecs, length(codecs) - index - 1)
  end
end
