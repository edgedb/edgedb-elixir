defmodule EdgeDB.Protocol.Error do
  defexception [
    :message,
    :name,
    :code,
    attributes: %{},
    tags: []
  ]

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

  @type option() ::
          {:code, integer()}
          | {:attributes, map()}
  @type options() :: list(option())
  @type tag() :: :should_retry | :should_reconnect
  @type t() :: %__MODULE__{
          message: String.t(),
          name: String.t(),
          code: integer(),
          attributes: map(),
          tags: list(tag())
        }

  @impl Exception
  def exception(message, opts \\ []) do
    code = Keyword.get(opts, :code)
    attributes = Keyword.get(opts, :attributes, %{})

    %__MODULE__{
      message: message,
      name: name_from_code(code),
      code: code,
      attributes: attributes,
      tags: tags_for_error(code)
    }
  end

  @impl Exception
  def message(%__MODULE__{} = exception) do
    "#{exception.name}: #{exception.message}"
  end

  @spec retry?(Exception.t()) :: boolean()

  def retry?(%__MODULE__{tags: tags}) do
    Enum.any?(tags, &(&1 == :should_retry))
  end

  def retry?(_other) do
    false
  end

  @spec reconnect?(Exception.t()) :: boolean()

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

    @spec unquote(snake_cased_name)(String.t(), options()) :: t()

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
