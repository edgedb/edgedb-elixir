defmodule EdgeDB.Protocol.Enum do
  alias EdgeDB.Protocol.Datatypes

  defmacro __using__(_opts \\ []) do
    quote do
      import EdgeDB.Protocol.Converters

      import unquote(__MODULE__)
    end
  end

  defmacro defenum(opts) do
    {:ok, values} = Keyword.fetch(opts, :values)
    guard = Keyword.get(opts, :guard)

    datatype_codec = Keyword.get(opts, :datatype, Datatypes.UInt8)

    codes = Keyword.values(values)
    atoms = Keyword.keys(values)

    t_typespec_ast = get_t_typespec(values)

    quote do
      @type t() :: unquote(t_typespec_ast)

      if not is_nil(unquote(guard)) do
        defguard unquote(guard)(code) when code in unquote(codes)
      end

      @spec to_atom(integer()) :: atom()
      def to_atom(code) when is_integer(code) and code in unquote(codes) do
        {atom, ^code} = List.keyfind(unquote(values), code, 1)
        atom
      end

      @spec to_atom(atom()) :: atom()
      def to_atom(atom) when is_atom(atom) and atom in unquote(atoms) do
        atom
      end

      @spec to_code(atom()) :: integer()
      def to_code(atom) when is_atom(atom) and atom in unquote(atoms) do
        {^atom, code} = List.keyfind(unquote(values), atom, 0)
        code
      end

      @spec to_code(integer()) :: integer()
      def to_code(code) when is_integer(code) and code in unquote(codes) do
        code
      end

      @spec encode(t()) :: bitstring()
      def encode(enum_value) do
        enum_value
        |> to_code()
        |> unquote(datatype_codec).encode()
      end

      @spec decode(bitstring()) :: {t(), bitstring()}
      def decode(<<content::binary>>) do
        {code, rest} = unquote(datatype_codec).decode(content)
        {to_atom(code), rest}
      end
    end
  end

  # generate typespec for enum, something like:
  # @type t() :: :value1 | 0xA | :value2 | 0xB | :value3 | 0xC

  defp get_t_typespec([{last_atom, last_number}]) do
    {:|, [], [last_atom, last_number]}
  end

  defp get_t_typespec([{current_atom, current_number} | rest]) do
    {:|, [], [current_atom, {:|, [], [current_number, get_t_typespec(rest)]}]}
  end
end
