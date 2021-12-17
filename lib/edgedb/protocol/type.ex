defmodule EdgeDB.Protocol.Type do
  @callback encode_type(term()) :: iodata()
  @callback decode_type(bitstring()) :: {term(), bitstring()}
  @optional_callbacks encode_type: 1, decode_type: 1

  defmacro __using__(_opts \\ []) do
    quote do
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)
    end
  end

  defmacro deftype(opts) do
    record_name = Keyword.fetch!(opts, :name)
    fields = Keyword.get(opts, :fields, [])
    record_def = EdgeDB.Protocol.Utils.define_record(record_name, fields)

    type_name_access_fun_def = define_type_name_access_fun(record_name)

    define_encoder? = Keyword.get(opts, :encode, true)
    define_decoder? = Keyword.get(opts, :decode, true)

    encoder_def = define_type_encoder(record_name)
    decoder_def = define_type_decoder()

    quote do
      @behaviour unquote(__MODULE__)

      unquote(record_def)
      unquote(type_name_access_fun_def)

      if unquote(define_encoder?) do
        unquote(encoder_def)
      end

      if unquote(define_decoder?) do
        unquote(decoder_def)
      end
    end
  end

  defp define_type_name_access_fun(name) do
    quote do
      @spec name() :: unquote(name)
      def name do
        unquote(name)
      end
    end
  end

  defp define_type_encoder(record_name) do
    quote do
      @spec encode(t() | list(t())) :: iodata()

      def encode(unquote(record_name)() = type) do
        encode_type(type)
      end

      @spec encode(list(t()), list(EdgeDB.Protocol.Utils.encoding_option())) :: iodata()
      def encode(types, opts \\ []) when is_list(types) do
        EdgeDB.Protocol.Utils.encode_list(&encode/1, types, opts)
      end
    end
  end

  defp define_type_decoder do
    quote do
      @spec decode(bitstring) :: {t(), bitstring()}
      def decode(<<data::binary>>) do
        decode_type(data)
      end

      @spec decode(non_neg_integer(), bitstring()) :: {list(t()), bitstring()}
      def decode(count, <<data::binary>>) do
        EdgeDB.Protocol.Utils.decode_list(&decode/1, count, data)
      end
    end
  end
end
