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
    values = Keyword.fetch!(opts, :values)
    union? = Keyword.get(opts, :union, false)
    typespec_def = define_typespec(values, union?)

    guard_name = Keyword.get(opts, :guard)
    codes = Keyword.values(values)
    guard_def = define_guard(guard_name, codes)

    to_atom_funs_def = define_to_atom_funs(values)
    to_code_funs_def = define_to_code_funs(values)

    datatype_codec = Keyword.get(opts, :datatype, Datatypes.UInt8)
    datatype_codec_access_fun_def = define_datatype_codec_access_fun(datatype_codec)

    encoder_def = define_enum_encoder(datatype_codec)
    decoder_def = define_enum_decoder(datatype_codec)

    quote do
      @behaviour unquote(__MODULE__)

      unquote(typespec_def)

      if not is_nil(unquote(guard_name)) do
        unquote(guard_def)
      end

      unquote(datatype_codec_access_fun_def)

      unquote(to_atom_funs_def)
      unquote(to_code_funs_def)

      unquote(encoder_def)
      unquote(decoder_def)

      defoverridable encode: 1, decode: 1
    end
  end

  defp define_typespec(values, union) do
    atoms = Keyword.keys(values)
    codes = Keyword.values(values)
    values = atoms ++ codes

    main_spec =
      values
      |> Enum.reverse()
      |> Enum.reduce(fn
        value, acc ->
          {:|, [], [value, acc]}
      end)

    if union do
      quote do
        @type t() :: list(unquote(main_spec))
      end
    else
      quote do
        @type t() :: unquote(main_spec)
      end
    end
  end

  defp define_guard(guard_name, codes) do
    quote do
      defguard unquote(guard_name)(code) when code in unquote(codes)
    end
  end

  defp define_to_atom_funs(values) do
    for {name, code} <- values do
      quote do
        @spec to_atom(unquote(code) | unquote(name)) :: unquote(name)

        def to_atom(unquote(code)) do
          unquote(name)
        end

        def to_atom(unquote(name)) do
          unquote(name)
        end
      end
    end
  end

  defp define_to_code_funs(values) do
    for {name, code} <- values do
      quote do
        @spec to_code(unquote(code) | unquote(name)) :: unquote(code)

        def to_code(unquote(code)) do
          unquote(code)
        end

        def to_code(unquote(name)) do
          unquote(code)
        end
      end
    end
  end

  defp define_datatype_codec_access_fun(codec) do
    quote do
      @spec enum_codec() :: module()
      def enum_codec do
        unquote(codec)
      end
    end
  end

  defp define_enum_encoder(codec) do
    quote do
      @spec encode(t()) :: iodata()
      def encode(value) do
        value
        |> to_code()
        |> unquote(codec).encode()
      end
    end
  end

  defp define_enum_decoder(codec) do
    quote do
      @spec decode(bitstring()) :: {t(), bitstring()}
      def decode(<<content::binary>>) do
        {code, rest} = unquote(codec).decode(content)
        {to_atom(code), rest}
      end
    end
  end
end
