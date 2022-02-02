defmodule EdgeDB.Error do
  @moduledoc """
  Exception returned by the driver if an error occurred.

  Most of the functions in the `EdgeDB.Error` module are a shorthands for simplifying `EdgeDB.Error` exception
    constructing. These functions are generated at compile time from a copy of the
    [`errors.txt`](https://github.com/edgedb/edgedb/blob/a529aae753319f26cce942ae4fc7512dd0c5a37b/edb/api/errors.txt) file.
  """

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

  @tags_to_atoms %{
    "SHOULD_RETRY" => :should_retry,
    "SHOULD_RECONNECT" => :should_reconnect
  }
  @error_definition_regex ~r/^(?<error_code>0x(_[0-9A-Fa-f]{2}){4})\s*(?<error_name>\w+)/
  @error_tag_regex ~r/\s+#(\w+)/
  @edgedb_errors_file Path.join(
                        :code.priv_dir(:edgedb),
                        Path.join(["edgedb", "api", "errors.txt"])
                      )

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

  for line <- File.stream!(@edgedb_errors_file),
      Regex.match?(@error_definition_regex, line) do
    %{
      "error_code" => code_str,
      "error_name" => error
    } = Regex.named_captures(@error_definition_regex, line)

    snake_cased_name =
      error
      |> Macro.underscore()
      |> String.to_atom()

    tags =
      @error_tag_regex
      |> Regex.scan(line)
      |> Enum.reduce([], fn
        [], acc ->
          acc

        [_match, tag], acc ->
          [tag | acc]
      end)
      |> Enum.map(&Map.fetch!(@tags_to_atoms, &1))

    code_str =
      code_str
      |> String.replace_prefix("0x", "")
      |> String.replace("_", "")

    {code, ""} = Integer.parse(code_str, 16)

    @doc false
    @spec unquote(snake_cased_name)(String.t(), list(option())) :: t()

    # credo:disable-for-next-line Credo.Check.Readability.Specs
    def unquote(snake_cased_name)(msg, opts \\ []) do
      exception(msg, Keyword.merge(opts, code: unquote(code)))
    end

    defp name_from_code(unquote(code)) do
      unquote(error)
    end

    defp tags_for_error(unquote(code)) do
      unquote(tags)
    end
  end
end
