defmodule EdgeDB.Protocol.DataType do
  # credo:disable-for-this-file Credo.Check.Design.AliasUsage

  defmacro __using__(_opts \\ []) do
    quote do
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)
    end
  end

  defmacro defdatatype(opts) do
    quote do
      @type t() :: unquote(Keyword.fetch!(opts, :type))

      @spec encode([t()]) :: bitstring()
      def encode(types) when is_list(types) do
        encode(types, [])
      end

      @spec encode([t()], list()) :: bitstring()
      def encode(types, opts) when is_list(types) do
        length_data_type = Keyword.get(opts, :data_type, EdgeDB.Protocol.DataTypes.UInt16)
        encoded_data = Enum.map(types, &encode(&1))

        if Keyword.get(opts, :raw) do
          encoded_data
        else
          [length_data_type.encode(length(types)), encoded_data]
        end
      end

      @spec decode(non_neg_integer(), bitstring()) :: {[t()], bitstring()}
      def decode(0, data) do
        {[], data}
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
