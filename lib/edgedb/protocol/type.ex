defmodule EdgeDB.Protocol.Type do
  @callback encode_type(term()) :: iodata()
  @callback decode_type(bitstring()) :: {term(), bitstring()}
  @optional_callbacks encode_type: 1, decode_type: 1

  defmacro __using__(_opts \\ []) do
    quote do
      import Record

      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)
    end
  end

  defmacro deftype(opts) do
    {:ok, record_name} = Keyword.fetch(opts, :name)

    decode? = Keyword.get(opts, :decode?, true)
    encode? = Keyword.get(opts, :encode?, true)

    fields = Keyword.get(opts, :fields, [])
    defaults = Keyword.get(opts, :defaults, [])

    quote do
      @behaviour unquote(__MODULE__)

      unquote(EdgeDB.Protocol.define_edgedb_record(record_name, fields, defaults))

      if unquote(encode?) do
        @spec encode(t() | list(t())) :: iodata()

        def encode(unquote(record_name)() = type) do
          __MODULE__.encode_type(type)
        end

        @spec encode(list(t()), EdgeDB.Protocol.list_encoding_options()) :: iodata()
        def encode(types, opts \\ []) when is_list(types) do
          EdgeDB.Protocol.encode_list(&__MODULE__.encode/1, types, opts)
        end
      end

      if unquote(decode?) do
        @spec decode(bitstring) :: {t(), bitstring()}
        def decode(<<data::binary>>) do
          __MODULE__.decode_type(data)
        end

        @spec decode(non_neg_integer(), bitstring()) :: {list(t()), bitstring()}
        def decode(count, <<data::binary>>) do
          EdgeDB.Protocol.decode_list(&__MODULE__.decode/1, count, data)
        end
      end
    end
  end
end
