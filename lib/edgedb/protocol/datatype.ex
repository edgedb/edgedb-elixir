defmodule EdgeDB.Protocol.Datatype do
  @callback encode_datatype(term()) :: iodata()
  @callback decode_datatype(bitstring()) :: {term(), bitstring()}

  defmacro __using__(_opts \\ []) do
    quote do
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)
    end
  end

  defmacro defdatatype(opts \\ []) do
    type = Keyword.fetch!(opts, :type)

    quote do
      @behaviour unquote(__MODULE__)

      @type t() :: unquote(type)

      @spec encode(t() | list(t())) :: iodata()

      def encode(datatype) when not is_list(datatype) do
        __MODULE__.encode_datatype(datatype)
      end

      @spec encode(list(t()), EdgeDB.Protocol.list_encoding_options()) :: iodata()
      def encode(datatypes, opts \\ []) when is_list(datatypes) do
        EdgeDB.Protocol.encode_list(&__MODULE__.encode/1, datatypes, opts)
      end

      @spec decode(bitstring()) :: {t(), bitstring()}
      def decode(<<data::binary>>) do
        __MODULE__.decode_datatype(data)
      end

      @spec decode(non_neg_integer(), bitstring()) :: {list(t()), bitstring()}
      def decode(count, <<data::binary>>) do
        EdgeDB.Protocol.decode_list(&__MODULE__.decode/1, count, data)
      end
    end
  end
end
