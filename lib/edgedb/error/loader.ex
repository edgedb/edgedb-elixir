defmodule EdgeDB.Error.Loader do
  @moduledoc false

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

  @type error_description() :: %{
          parts: {integer(), integer(), integer(), integer()},
          code: integer(),
          name: String.t(),
          tags: list(atom())
        }

  @spec get_errors() :: list(error_description())
  def get_errors do
    cache = :ets.new(:errors_cache, [])

    errors =
      for line <- File.stream!(@edgedb_errors_file),
          Regex.match?(@error_definition_regex, line) do
        %{
          "error_code" => code_str,
          "error_name" => error
        } = Regex.named_captures(@error_definition_regex, line)

        code_str = String.replace_prefix(code_str, "0x", "")

        [p1, p2, p3, p4] =
          code_str
          |> String.split("_")
          |> Enum.slice(1..4)
          |> Enum.map(fn part ->
            {part, ""} = Integer.parse(part, 16)
            part
          end)

        parts = {p1, p2, p3, p4}

        {code, ""} =
          code_str
          |> String.replace("_", "")
          |> Integer.parse(16)

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

        error = %{
          parts: parts,
          code: code,
          name: error,
          tags: tags
        }

        :ets.insert(cache, {parts, error})

        error
      end

    Enum.map(errors, fn error ->
      parent_tags = get_parents_tags(cache, error.parts)
      %{error | tags: error.tags ++ parent_tags}
    end)
  end

  defp get_parents_tags(_cache, {_p1, 0, 0, 0}) do
    []
  end

  defp get_parents_tags(cache, parts) do
    parent_parts =
      case parts do
        {p1, _p2, 0, 0} ->
          {p1, 0, 0, 0}

        {p1, p2, _p3, 0} ->
          {p1, p2, 0, 0}

        {p1, p2, p3, _p4} ->
          {p1, p2, p3, 0}
      end

    [{^parent_parts, desc}] = :ets.lookup(cache, parent_parts)

    desc.tags ++ get_parents_tags(cache, parent_parts)
  end
end
