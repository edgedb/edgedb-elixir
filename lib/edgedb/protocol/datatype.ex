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

    typespec_def = define_datatype_typespec(type)

    encoder_def = define_datatype_encoder()
    decoder_def = define_datatype_decoder()

    quote do
      @behaviour unquote(__MODULE__)

      unquote(typespec_def)
      unquote(encoder_def)
      unquote(decoder_def)
    end
  end

  defp define_datatype_typespec(type) do
    quote do
      @type t() :: unquote(type)
    end
  end

  defp define_datatype_encoder do
    quote do
      @spec encode(t() | list(t())) :: iodata()

      def encode(datatype) when not is_list(datatype) do
        encode_datatype(datatype)
      end

      @spec encode(list(t()), list(EdgeDB.Protocol.Utils.encoding_option())) :: iodata()
      def encode(datatypes, opts \\ []) when is_list(datatypes) do
        EdgeDB.Protocol.Utils.encode_list(&encode/1, datatypes, opts)
      end
    end
  end

  defp define_datatype_decoder do
    quote do
      @spec decode(bitstring()) :: {t(), bitstring()}
      def decode(<<data::binary>>) do
        decode_datatype(data)
      end

      @spec decode(non_neg_integer(), bitstring()) :: {list(t()), bitstring()}
      def decode(count, <<data::binary>>) do
        EdgeDB.Protocol.Utils.decode_list(&decode/1, count, data)
      end
    end
  end
end
