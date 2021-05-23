defmodule EdgeDB.Protocol.Type do
  # credo:disable-for-this-file Credo.Check.Design.AliasUsage

  defmacro __using__(_opts \\ []) do
    quote do
      import Record

      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)
    end
  end

  defmacro deftype(opts) do
    {:ok, record_name} = Keyword.fetch(opts, :name)

    add_decode? = Keyword.get(opts, :decode?, true)
    add_encode? = Keyword.get(opts, :encode?, true)

    defaults = Keyword.get(opts, :defaults, [])

    default_keys = Keyword.keys(defaults)

    quote do
      defrecord unquote(record_name),
                unquote(
                  opts
                  |> Keyword.get(:fields, [])
                  |> Keyword.drop(default_keys)
                  |> Keyword.keys()
                ) ++ unquote(defaults)

      @type t() :: record(unquote(record_name), unquote(Keyword.get(opts, :fields, [])))

      if unquote(add_encode?) do
        @spec encode([t()]) :: iodata()
        def encode(types) when is_list(types) do
          encode(types, [])
        end

        @spec encode([t()], list()) :: iodata()
        def encode(types, opts) when is_list(types) do
          length_data_type = Keyword.get(opts, :data_type, EdgeDB.Protocol.DataTypes.UInt16)
          encoded_data = Enum.map(types, &encode(&1))

          if Keyword.get(opts, :raw) do
            encoded_data
          else
            [length_data_type.encode(length(types)), encoded_data]
          end
        end
      end

      if unquote(add_decode?) do
        @spec decode(pos_integer(), bitstring()) :: {[t()], bitstring()}

        def decode(0, <<value_to_decode::binary>>) do
          {[], value_to_decode}
        end

        def decode(num_types_to_decode, <<value_to_decode::binary>>) do
          {types, rest} =
            Enum.reduce(1..num_types_to_decode, {[], value_to_decode}, fn _idx, {types, rest} ->
              {decoded_type, rest} = decode(rest)
              {[decoded_type | types], rest}
            end)

          types = Enum.reverse(types)

          {types, rest}
        end
      end
    end
  end
end
