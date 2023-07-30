defmodule EdgeDB.Docs do
  @moduledoc false

  @skip_pages ~w(CHANGELOG.md)

  @error_group :Errors
  @api_group :API

  @index_page "pages/md/main.md"
  @index_path "pages/rst/index.rst"
  @docs_path "pages/rst"
  @api_path "pages/rst/api"

  @line_length 145
  @id_prefix "_edgedb-elixir"

  def generate do
    File.mkdir(@docs_path)

    docs_config = EdgeDB.MixProject.project()[:docs]
    pages = docs_config[:extras] -- @skip_pages
    groups = [{@api_group, []} | docs_config[:groups_for_modules]]
    errors = groups[@error_group]

    groups =
      Keyword.update!(groups, @error_group, fn _mods ->
        [EdgeDB.Error]
      end)

    Enum.each(pages, fn
      @index_page ->
        toc = generate_toc(pages, groups)
        content = page_to_rst(@index_page)
        [header, underscores, content] = String.split(content, "\n", parts: 3)

        content =
          Enum.join(
            [
              ".. #{@id_prefix}-intro:",
              "#{header}\n#{underscores}",
              toc,
              content
            ],
            "\n\n"
          )

        File.write!(@index_path, content)

      page ->
        name = file_to_name(page)

        content =
          page
          |> page_to_rst()
          |> add_ref(name)

        page
        |> rst_path()
        |> File.write!(content)
    end)

    generate_api_docs(groups, errors)
  end

  defp file_to_name(path) do
    path
    |> Path.basename()
    |> Path.rootname()
  end

  defp group_to_name(group) do
    group
    |> to_string()
    |> String.downcase()
    |> String.replace(" ", "-")
  end

  defp generate_toc(pages, groups) do
    pages = Enum.map(pages, &file_to_name/1) -- ["main"]

    groups =
      Enum.map(groups, fn
        {group, _mods} ->
          "api/#{group_to_name(group)}"
      end)

    """
    .. toctree::
      :maxdepth: 3
      :hidden:

      #{Enum.join(pages, "\n  ")}
      #{Enum.join(groups, "\n  ")}
    """
  end

  defp rst_path(path) do
    Path.join(@docs_path, "#{file_to_name(path)}.rst")
  end

  defp page_to_rst(path) do
    path
    |> File.read!()
    |> convert_md_to_rst()
  end

  defp generate_api_docs(groups, errors) do
    File.mkdir(@api_path)

    group_docs =
      fetch_edgedb_docs(groups, errors)

    Enum.map(group_docs, fn {group, mods} ->
      group_name = group_to_name(group)

      content =
        group
        |> generate_md_for_group(mods)
        |> convert_md_to_rst()
        |> fix_links(group_name)

      @api_path
      |> Path.join("#{group_name}.rst")
      |> File.write!(add_ref(content, "api-#{group_name}"))
    end)
  end

  defp generate_md_for_group(group, mods) do
    header =
      if group == :API do
        "API"
      else
        "API/#{group}"
      end

    "# #{header}\n\n" <>
      Enum.map_join(mods, "\n\n", fn {mod, {%{"en" => mod_doc}, docs}} ->
        types_specs = get_typespecs_for_module(mod)

        types_docs =
          docs
          |> get_docs_for_kind(:type)
          |> Enum.map(fn {{_kind, name, arity}, _annotation, _signature, %{"en" => doc}, _meta} ->
            {kind, typespec} = types_specs[{name, arity}]

            """
            #### *type* `#{inspect(mod)}.#{to_string(name)}/#{arity}`

            ```elixir
            #{kind} #{inspect(mod)}.#{typespec}
            ```

            #{doc}
            """
          end)

        callbacks_specs = get_callbacks_for_module(mod)

        callbacks_docs =
          docs
          |> get_docs_for_kind(:callback)
          |> Enum.map(fn {{_kind, name, arity}, _annotation, _signature, %{"en" => doc}, _meta} ->
            specs =
              Enum.map_join(callbacks_specs[{name, arity}], "\n", fn spec ->
                "@spec #{inspect(mod)}.#{spec}"
              end)

            """
            #### *callback* `#{inspect(mod)}.#{to_string(name)}/#{arity}`

            ```elixir
            #{specs}
            ```

            #{doc}
            """
          end)

        functiona_specs = get_specs_for_module(mod)

        functions_docs =
          docs
          |> get_docs_for_kind(:function)
          |> Enum.map(fn {{_kind, name, arity}, _annotation, [signature], %{"en" => doc}, _meta} ->
            specs =
              Enum.map_join(functiona_specs[{name, arity}], "\n", fn spec ->
                "@spec #{inspect(mod)}.#{spec}"
              end)

            """
            #### *function* `#{inspect(mod)}.#{signature}`

            ```elixir
            #{specs}
            ```

            #{doc}
            """
          end)

        doc =
          """
          ## #{inspect(mod)}

          #{mod_doc}
          """

        doc =
          if length(types_docs) != 0 do
            """
            #{doc}

            ### Types

            #{Enum.join(types_docs, "\n\n")}
            """
          else
            doc
          end

        if length(callbacks_docs) != 0 do
          """
          #{doc}

          ### Callbacks

          #{Enum.join(callbacks_docs, "\n\n")}
          """
        else
          doc
        end

        if length(functions_docs) != 0 do
          """
          #{doc}

          ### Functions

          #{Enum.join(functions_docs, "\n\n")}
          """
        else
          doc
        end
      end)
  end

  defp fetch_edgedb_docs(groups, errors) do
    {:ok, modules} = :application.get_key(:edgedb, :modules)

    modules
    |> Enum.map(fn module ->
      {module, Code.fetch_docs(module)}
    end)
    |> Enum.filter(fn
      {_mod, {:docs_v1, _annotation, _lang, _format, mod_doc, _meta, _docs}}
      when mod_doc in [:none, :hidden] ->
        false

      {_mod, {:error, _reason}} ->
        false

      {mod, _doc} ->
        mod not in errors
    end)
    |> Enum.sort(:desc)
    |> Enum.reduce(groups, fn
      {mod, {:docs_v1, _annotation, _lang, _format, mod_doc, _meta, docs}}, acc ->
        group =
          Enum.find_value(acc, :API, fn {group, mods} ->
            cond do
              mod in mods ->
                group

              true ->
                nil
            end
          end)

        docs =
          Enum.filter(docs, fn
            {_type, _annotation, _signature, doc, _meta} when doc in [:none, :hidden] ->
              false

            _other ->
              true
          end)

        Keyword.update!(acc, group, fn mods ->
          # credo:disable-for-next-line Credo.Check.Refactor.Nesting
          if mod in mods do
            mod_idx = Enum.find_index(mods, &(&1 == mod))
            List.replace_at(mods, mod_idx, {mod, {mod_doc, docs}})
          else
            [{mod, {mod_doc, docs}} | mods]
          end
        end)
    end)
  end

  defp convert_md_to_rst(md) do
    {:ok, rst} =
      md
      |> fix_md()
      |> Panpipe.pandoc(to: "rst", column: @line_length, reference_links: true)

    fix_rst(rst)
  end

  defp fix_md(md) do
    md
    |> drop_exdoc_features()
  end

  defp fix_rst(rst) do
    rst
    |> fix_notes()
  end

  defp fix_links(rst, group_name) do
    rst
    |> String.replace("_functions-", "#{@id_prefix}-#{group_name}-functions-")
    |> String.replace("_types-", "#{@id_prefix}-#{group_name}-types-")
  end

  defp get_typespecs_for_module(mod) do
    {:ok, specs} = Code.Typespec.fetch_types(mod)

    Enum.reduce(specs, %{}, fn
      {:type, {name, _def, vars} = spec}, acc ->
        spec =
          spec
          |> Code.Typespec.type_to_quoted()
          |> Macro.to_string()
          |> Code.format_string!()
          |> IO.iodata_to_binary()

        Map.put(acc, {name, length(vars)}, {"@type", spec})

      {:opaque, {name, _def, vars}}, acc ->
        spec =
          {name, nil, vars}
          |> Code.Typespec.type_to_quoted()
          |> Macro.to_string()
          |> Code.format_string!()
          |> IO.iodata_to_binary()

        [spec, _rest] = String.split(spec, "::")

        Map.put(acc, {name, length(vars)}, {"@opaque", String.trim(spec)})

      _other, acc ->
        acc
    end)
  end

  defp get_callbacks_for_module(mod) do
    {:ok, specs} = Code.Typespec.fetch_callbacks(mod)

    Enum.reduce(specs, %{}, fn {{name, arity}, specs}, acc ->
      specs =
        Enum.map(specs, fn spec ->
          name
          |> Code.Typespec.spec_to_quoted(spec)
          |> Macro.to_string()
          |> Code.format_string!()
        end)

      Map.put(acc, {name, arity}, specs)
    end)
  end

  defp get_specs_for_module(mod) do
    {:ok, specs} = Code.Typespec.fetch_specs(mod)

    Enum.reduce(specs, %{}, fn {{name, arity}, specs}, acc ->
      specs =
        Enum.map(specs, fn spec ->
          name
          |> Code.Typespec.spec_to_quoted(spec)
          |> Macro.to_string()
          |> Code.format_string!()
        end)

      Map.put(acc, {name, arity}, specs)
    end)
  end

  defp get_docs_for_kind(docs, kind) do
    docs
    |> Enum.filter(fn
      {{^kind, _name, _arity}, _annotation, _signature, _doc, _meta} ->
        true

      _other ->
        false
    end)
    |> Enum.sort_by(
      fn {{_kind, name, arity}, _annotation, _signature, _doc, _meta} ->
        {to_string(name), arity}
      end,
      :asc
    )
  end

  defp drop_exdoc_features(content) do
    String.replace(content, "`t:", "`")
  end

  defp fix_notes(content) do
    content
    |> String.replace(~r/.*rubric::\sNOTE.*/, ".. note::")
    |> String.replace(~r/.*note-\.warning.*/, "")
  end

  defp add_ref(content, name) do
    ".. #{@id_prefix}-#{name}:\n\n" <> content
  end
end

EdgeDB.Docs.generate()
