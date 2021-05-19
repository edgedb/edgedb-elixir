defmodule EdgeDB.Protocol.Type do
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
        @spec encode([t()]) :: bitstring()
        def encode(types) when is_list(types) do
          [EdgeDB.Protocol.DataTypes.UInt16.encode(length(types)), encode(types, :raw)]
        end

        @spec encode([t()], :raw) :: bitstring()
        def encode(types, :raw) when is_list(types) do
          Enum.map(types, &encode(&1))
        end
      end

      if unquote(add_decode?) do
        @spec decode(pos_integer(), bitstring()) :: {[t()], bitstring()}

        def decode(0, <<value_to_decode::binary>>) do
          {[], value_to_decode}
        end

        def decode(num_types_to_decode, <<value_to_decode::binary>>) do
          {types, rest} =
            Enum.reduce(1..num_types_to_decode, {[], value_to_decode}, fn _, {types, rest} ->
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
