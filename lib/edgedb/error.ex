defmodule EdgeDB.Error do
  @moduledoc """
  Exception returned by the client if an error occurred.

  Most of the functions in the `EdgeDB.Error` module are a shorthands for simplifying `EdgeDB.Error` exception
    constructing. These functions are generated at compile time from a copy of the
    [errors.txt](https://github.com/edgedb/edgedb/blob/a529aae753319f26cce942ae4fc7512dd0c5a37b/edb/api/errors.txt) file.

  The useful ones are:

    * `EdgeDB.Error.retry?/1`
    * `EdgeDB.Error.inheritor?/2`

  By default the client generates exception messages in full format, attempting to output all useful
    information about the error location if it is possible.

  This behavior can be disabled by using the `:render_error_hints` configuration of the `:edgedb` application.

  The renderer also tries to colorize the output message. This behavior defaults to `IO.ANSI.enabled?/0`,
    but can also be configured with the `:rended_colored_errors` setting for the `:edgedb` application.
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
    render_hints? = Application.get_env(:edgedb, :render_error_hints, true)
    color_errors? = Application.get_env(:edgedb, :rended_colored_errors, IO.ANSI.enabled?())

    config = generate_render_config(exception, render_hints?, color_errors?)
    generate_message(exception, config)
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

  defp generate_message(
         %__MODULE__{
           query: %EdgeDB.Query{statement: query}
         } = exception,
         %{start: start} = config
       )
       when start >= 0 do
    lines =
      query
      |> String.split("\n")
      |> Enum.map(&"#{&1}\n")

    padding =
      lines
      |> length()
      |> Integer.digits()
      |> length()

    config = Map.put(config, :padding, padding)

    {_config, lines} =
      lines
      |> Enum.with_index(1)
      |> Enum.reduce_while({config, []}, fn {line, idx}, {config, lines} ->
        line_size = string_length(line)
        line = String.trim_trailing(line)

        case render_line(line, line_size, to_string(idx), config, lines) do
          {:rendered, {config, lines}} ->
            {:cont, {config, lines}}

          {:finished, {config, lines}} ->
            {:halt, {config, lines}}
        end
      end)

    [
      [:reset, "#{exception.name}: "],
      [:bright, "#{exception.message}", "\n"],
      [:blue, "#{String.pad_leading("", padding)} ┌─ "],
      [:reset, "query:#{config.line}:#{config.col}", "\n"],
      [:blue, "#{String.pad_leading("", padding)} │", "\n"]
      | Enum.reverse(lines)
    ]
    |> IO.ANSI.format(config.use_color)
    |> IO.iodata_to_binary()
  end

  defp generate_message(%__MODULE__{} = exception, _config) do
    "#{exception.name}: #{exception.message}"
  end

  defp generate_render_config(%__MODULE__{} = exception, true, color_errors?) do
    position_start =
      case Integer.parse(exception.attributes[:character_start] || "") do
        {position_start, ""} ->
          position_start

        :error ->
          -1
      end

    position_end =
      case Integer.parse(exception.attributes[:character_end] || "") do
        {position_end, ""} ->
          position_end

        :error ->
          -1
      end

    %{
      start: position_start,
      offset: max(1, position_end - position_start),
      line: exception.attributes[:line_start] || "?",
      col: exception.attributes[:column_start] || "?",
      hint: exception.attributes[:hint] || "error",
      use_color: color_errors?
    }
  end

  defp generate_render_config(%__MODULE__{}, _render_hints?, _color_errors?) do
    %{}
  end

  defp render_line(_line, line_size, _line_num, %{start: start} = config, lines)
       when start >= line_size do
    {:rendered, {%{config | start: start - line_size}, lines}}
  end

  defp render_line(line, line_size, line_num, config, lines) do
    {line, line_size, config, lines} = render_border(line, line_size, line_num, config, lines)

    render_error(line, line_size, config, lines)
  end

  defp render_border(line, line_size, line_num, %{start: start} = config, lines)
       when start >= 0 do
    {first_half, line} = split_string_at(line, config.start)
    line_size = line_size - config.start

    lines = [
      [
        [:blue, "#{String.pad_leading(line_num, config.padding)} │   "],
        [:reset, first_half]
      ]
      | lines
    ]

    config = %{config | start: unicode_width(first_half)}

    {line, line_size, config, lines}
  end

  defp render_border(line, line_size, line_num, config, lines) do
    lines = [
      [
        [:blue, "#{String.pad_leading(line_num, config.padding)} │ "],
        [:red, "│ "]
      ]
      | lines
    ]

    {line, line_size, config, lines}
  end

  defp render_error(line, line_size, %{offset: offset, start: start} = config, lines)
       when offset > line_size and start >= 0 do
    lines = [
      [
        [:red, line, "\n"],
        [:blue, "#{String.pad_leading("", config.padding)} │ "],
        [:red, "╭─#{String.duplicate("─", config.start)}^", "\n"]
      ]
      | lines
    ]

    config = %{config | offset: config.offset - line_size, start: -1}
    {:rendered, {config, lines}}
  end

  defp render_error(line, line_size, %{offset: offset} = config, lines) when offset > line_size do
    lines = [[:red, line, "\n"] | lines]

    config = %{config | offset: config.offset - line_size, start: -1}
    {:rendered, {config, lines}}
  end

  defp render_error(line, _line_size, %{start: start} = config, lines) when start >= 0 do
    {first_half, line} = split_string_at(line, config.offset)
    error_width = unicode_width(first_half)
    padding_string = String.pad_leading("", config.padding)

    lines = [
      [
        [:red, first_half],
        [:reset, line, "\n"],
        [:blue, "#{padding_string} │   #{String.duplicate(" ", config.start)}"],
        [:red, "#{String.duplicate("^", error_width)} #{config.hint}"]
      ]
      | lines
    ]

    {:finished, {config, lines}}
  end

  defp render_error(line, _line_size, config, lines) do
    {first_half, line} = split_string_at(line, config.offset)
    error_width = unicode_width(first_half)

    lines = [
      [
        [:red, first_half],
        [:reset, line, "\n"],
        [:blue, "#{String.duplicate(" ", config.padding)} │ "],
        [:red, "╰─#{String.duplicate("─", error_width - 1)}^ #{config.hint}"]
      ]
      | lines
    ]

    {:finished, {config, lines}}
  end

  defp string_length(text) do
    text
    |> String.codepoints()
    |> length
  end

  defp unicode_width(text) do
    Ucwidth.width(text)
  end

  defp split_string_at(text, position) do
    codes = String.codepoints(text)
    {list1, list2} = Enum.split(codes, position)
    {Enum.join(list1), Enum.join(list2)}
  end
end
