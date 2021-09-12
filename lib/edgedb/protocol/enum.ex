defmodule EdgeDB.Protocol.Enum do
  alias EdgeDB.Protocol.Datatypes

  @callback to_atom(integer() | atom()) :: atom()
  @callback to_code(atom() | integer()) :: integer()
  @callback encode(term()) :: iodata()
  @callback decode(bitstring()) :: {term(), bitstring()}

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
      @behaviour unquote(__MODULE__)

      @type t() :: unquote(t_typespec_ast)

      @datatype unquote(datatype_codec)

      if not is_nil(unquote(guard)) do
        defguard unquote(guard)(code) when code in unquote(codes)
      end

      @impl unquote(__MODULE__)
      def to_atom(code) when is_integer(code) and code in unquote(codes) do
        {atom, ^code} = List.keyfind(unquote(values), code, 1)
        atom
      end

      @impl unquote(__MODULE__)
      def to_atom(atom) when is_atom(atom) and atom in unquote(atoms) do
        atom
      end

      @impl unquote(__MODULE__)
      def to_code(atom) when is_atom(atom) and atom in unquote(atoms) do
        {^atom, code} = List.keyfind(unquote(values), atom, 0)
        code
      end

      @impl unquote(__MODULE__)
      def to_code(code) when is_integer(code) and code in unquote(codes) do
        code
      end

      @impl unquote(__MODULE__)
      def encode(enum_value) do
        enum_value
        |> to_code()
        |> @datatype.encode()
      end

      @impl unquote(__MODULE__)
      def decode(<<content::binary>>) do
        {code, rest} = @datatype.decode(content)
        {to_atom(code), rest}
      end

      defoverridable encode: 1, decode: 1
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
