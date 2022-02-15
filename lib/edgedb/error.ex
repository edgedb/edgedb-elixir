defmodule EdgeDB.Error do
  @moduledoc """
  Exception returned by the driver if an error occurred.

  Most of the functions in the `EdgeDB.Error` module are a shorthands for simplifying `EdgeDB.Error` exception
    constructing. These functions are generated at compile time from a copy of the
    [`errors.txt`](https://github.com/edgedb/edgedb/blob/a529aae753319f26cce942ae4fc7512dd0c5a37b/edb/api/errors.txt) file.
  """

  alias EdgeDB.Error.Loader

  defexception [
    :message,
    :name,
    :code,
    attributes: %{},
    tags: [],
    query: nil
  ]

  @typedoc """
  Exception returned by the driver if an error occurred.

  Fields:

    * `:message` - human-readable error message.
    * `:name` - error name from EdgeDB.
    * `:code` - internal error code.
    * `:attributes` - additional error attributes that can be obtained from the
      [`ErrorResponse`](https://www.edgedb.com/docs/reference/protocol/messages#ref-protocol-msg-error) server message.
    * `:tags` - error tags.
    * `:query` - query, which should have been executed when the error occurred.
  """
  @type t() :: %__MODULE__{
          message: String.t(),
          name: String.t(),
          code: integer(),
          attributes: map(),
          tags: list(tag()),
          query: EdgeDB.Query.t() | nil
        }

  @typedoc """
  Options for constructing an `EdgeDB.Error` instance.

  Supported options:

    * `:code` - internal error code.
    * `:attributes` - additional error attributes that can be obtained from the
      [`ErrorResponse`](https://www.edgedb.com/docs/reference/protocol/messages#ref-protocol-msg-error) server message.
    * `:query` - query, which should have been executed when the error occurred.
  """
  @type option() ::
          {:code, integer()}
          | {:attributes, map()}
          | {:query, EdgeDB.Query.t()}

  @typedoc """
  Error tags.
  """
  @type tag() :: :should_retry | :should_reconnect

  Module.register_attribute(__MODULE__, :supported_error_types, accumulate: true)

  @impl Exception
  def exception(message, opts \\ []) do
    code = Keyword.get(opts, :code)
    attributes = Keyword.get(opts, :attributes, %{})
    query = opts[:query]

    %__MODULE__{
      message: message,
      name: name_from_code(code),
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

  for error_desc <- Loader.get_errors() do
    snake_cased_name =
      error_desc.name
      |> Macro.underscore()
      |> String.to_atom()

    Module.put_attribute(__MODULE__, :supported_error_types, snake_cased_name)

    @spec unquote(snake_cased_name)(String.t(), list(option())) :: t()

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
  end

  @doc """
  Check if the exception is an inheritor of another EdgeDB error.
  """
  @spec inheritor?(t(), atom()) :: boolean()
  def inheritor?(exception, base_error_type)

  def inheritor?(%__MODULE__{code: code}, base_error_type)
      when base_error_type in @supported_error_types do
    base_error = apply(__MODULE__, base_error_type, [""])
    Bitwise.band(base_error.code, code) == base_error.code
  end

  def inheritor?(_exception, _error_type) do
    false
  end
end
