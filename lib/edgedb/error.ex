defmodule EdgeDB.Error do
  @moduledoc """
  Exception returned by the client if an error occurred.

  Most of the functions in the `EdgeDB.Error` module are a shorthands for simplifying `EdgeDB.Error` exception
    constructing. These functions are generated at compile time from a copy of the
    [`errors.txt`](https://github.com/edgedb/edgedb/blob/a529aae753319f26cce942ae4fc7512dd0c5a37b/edb/api/errors.txt) file.

  The useful ones are:

    * `EdgeDB.Error.retry?/1`
    * `EdgeDB.Error.inheritor?/2`
  """

  alias EdgeDB.Error.Parser

  defexception [
    :message,
    :type,
    :name,
    :code,
    attributes: %{},
    tags: [],
    query: nil
  ]

  @typedoc """
  Exception returned by the client if an error occurred.

  Fields:

    * `:message` - human-readable error message.
    * `:type` - alias module for EdgeDB error.
    * `:name` - error name from EdgeDB.
    * `:code` - internal error code.
  """
  @type t() :: %{
          __struct__: __MODULE__,
          message: String.t(),
          type: module(),
          name: String.t(),
          code: integer()
        }

  @typedoc false
  @type tag() :: :should_retry | :should_reconnect

  Module.register_attribute(__MODULE__, :supported_error_types, accumulate: true)

  @impl Exception
  def exception(message, opts \\ []) do
    code = Keyword.get(opts, :code)
    attributes = Keyword.get(opts, :attributes, %{})
    query = opts[:query]

    name = name_from_code(code)

    %__MODULE__{
      message: message,
      type: type_from_name(name),
      name: name,
      code: code,
      attributes: attributes,
      tags: tags_for_error(code),
      query: query
    }
  end

  @impl Exception
  def message(%__MODULE__{} = exception) do
    "#{exception.name}: #{exception.message}"
  end

  @doc """
  Check if should try to repeat the query during the execution of which an error occurred.
  """
  @spec retry?(Exception.t()) :: boolean()
  def retry?(exception)

  def retry?(%__MODULE__{tags: tags}) do
    Enum.any?(tags, &(&1 == :should_retry))
  end

  def retry?(_other) do
    false
  end

  @doc """
  Check if should try to reconnect to EdgeDB server.

  **NOTE**: this function is not used right now, because `DBConnection` reconnects it connection itself.
  """
  @spec reconnect?(Exception.t()) :: boolean()
  def reconnect?(exception)

  def reconnect?(%__MODULE__{tags: tags}) do
    Enum.any?(tags, &(&1 == :should_reconnect))
  end

  def reconnect?(_other) do
    false
  end

  for error_desc <- Parser.parse_errors() do
    # create a module for error type with shorthand builder

    # we generate some module code here, so it's safe to call String.to_atom/1
    # or Module.concat/1

    # credo:disable-for-lines:4 Credo.Check.Warning.UnsafeToAtom
    snake_cased_name =
      error_desc.name
      |> Macro.underscore()
      |> String.to_atom()

    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    error_mod_name = Module.concat([EdgeDB, error_desc.name])

    error_mod_ast =
      quote do
        @moduledoc since: "0.3.0"
        @moduledoc """
        A shorthand module to create `EdgeDB.Error` of `#{inspect(__MODULE__)}` type.
        """

        alias EdgeDB.Error

        # we're hiding some internal stuff for EdgeDB.Error and dialyzer doesn't like that.
        @dialyzer {:nowarn_function, new: 2}

        @doc """
        Create a new `EdgeDB.Error` with `#{inspect(__MODULE__)}` type.
        """
        @spec new(String.t(), Keyword.t()) :: EdgeDB.Error.t()
        def new(message, opts \\ []) do
          EdgeDB.Error.unquote(snake_cased_name)(message, opts)
        end
      end

    Module.create(error_mod_name, error_mod_ast, Macro.Env.location(__ENV__))

    Module.put_attribute(__MODULE__, :supported_error_types, error_mod_name)

    # we're hiding some internal stuff for EdgeDB.Error and dialyzer doesn't like that.
    @dialyzer {:nowarn_function, {snake_cased_name, 2}}

    @spec unquote(snake_cased_name)(String.t(), Keyword.t()) :: t()

    @doc """
    Create a new `EdgeDB.Error` with `#{inspect(error_mod_name)}` type.
    """

    # credo:disable-for-next-line Credo.Check.Readability.Specs
    def unquote(snake_cased_name)(msg, opts \\ []) do
      exception(msg, Keyword.merge(opts, code: unquote(error_desc.code)))
    end

    defp name_from_code(unquote(error_desc.code)) do
      unquote(error_desc.name)
    end

    defp tags_for_error(unquote(error_desc.code)) do
      unquote(error_desc.tags)
    end

    defp type_from_name(unquote(error_desc.name)) do
      unquote(error_mod_name)
    end
  end

  @doc since: "0.2.0"
  @doc """
  Check if the exception is an inheritor of another EdgeDB error.
  """
  @spec inheritor?(t(), module()) :: boolean()
  def inheritor?(exception, base_error_type)

  def inheritor?(%__MODULE__{code: code}, base_error_type)
      when base_error_type in @supported_error_types do
    base_error = base_error_type.new("")
    Bitwise.band(base_error.code, code) == base_error.code
  end

  def inheritor?(_exception, _error_type) do
    false
  end
end
