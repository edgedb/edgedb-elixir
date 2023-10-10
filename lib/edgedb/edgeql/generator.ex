defmodule EdgeDB.EdgeQL.Generator do
  @moduledoc false

  alias EdgeDB.Protocol.{
    Codecs,
    CodecStorage
  }

  require EEx

  @builtin_scalars_to_typespecs %{
    Codecs.UUID => {"std::uuid", "binary()"},
    Codecs.Str => {"std::str", "String.t()"},
    Codecs.Bytes => {"std::bytes", "bitstring()"},
    Codecs.Int16 => {"std::int16", "integer()"},
    Codecs.Int32 => {"std::int32", "integer()"},
    Codecs.Int64 => {"std::int64", "integer()"},
    Codecs.Float32 => {"std::float32", "float()"},
    Codecs.Float64 => {"std::float64", "float()"},
    Codecs.Decimal => {"std::decimal", "Decimal.t()"},
    Codecs.Bool => {"std::bool", "boolean()"},
    Codecs.DateTime => {"std::datetime", "DateTime.t()"},
    Codecs.Duration => {"std::duration", "integer()"},
    Codecs.JSON => {"std::json", "any()"},
    Codecs.LocalDateTime => {"cal::local_datetime", "NaiveDateTime.t()"},
    Codecs.LocalDate => {"cal::local_date", "Date.t()"},
    Codecs.LocalTime => {"cal::local_time", "Time.t()"},
    Codecs.BigInt => {"std::bigint", "Decimal.t()"},
    Codecs.RelativeDuration => {"cal::relative_duration", "EdgeDB.RelativeDuration.t()"},
    Codecs.DateDuration => {"cal::date_duration", "EdgeDB.DateDuration.t()"},
    Codecs.ConfigMemory => {"cfg::memory", "EdgeDB.ConfigMemory.t()"},
    Codecs.Vector => {"ext::pgvector::vector", "[float()]"}
  }
  @scalar_codecs Map.keys(@builtin_scalars_to_typespecs)

  @field_is_implicit Bitwise.bsl(1, 0)
  @field_is_link_property Bitwise.bsl(1, 1)

  @types_tab :edgedb_edgeql_gen_types

  @default_output "./lib/"
  @cardinality_to_function %{
    no_result: "execute",
    at_most_one: "query_single",
    one: "query_required_single",
    at_least_one: "query",
    many: "query"
  }

  @query_template Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "query.ex.eex"])
  @shape_template Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "_shape.eex"])
  @schema_template Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "_schema.eex"])
  @builtin_template Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "_builtin.eex"])
  @object_template Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "_object.eex"])
  @set_template Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "_set.eex"])

  EEx.function_from_file(:defp, :render_query_template, @query_template, [:assigns])
  EEx.function_from_file(:defp, :render_shape_template, @shape_template, [:assigns])
  EEx.function_from_file(:defp, :render_schema_template, @schema_template, [:assigns])
  EEx.function_from_file(:defp, :render_builtin_template, @builtin_template, [:assigns])
  EEx.function_from_file(:defp, :render_object_template, @object_template, [:assigns])
  EEx.function_from_file(:defp, :render_set_template, @set_template, [:assigns])

  @spec generate(Keyword.t()) :: {:ok, %{Path.t() => Path.t()}} | {:error, term()}
  def generate(opts) do
    silent? = Keyword.get(opts, :silent, false)

    {:ok, client} =
      opts
      |> Keyword.merge(
        max_concurrency: 1,
        queue_target: :timer.seconds(30),
        queue_interval: :timer.seconds(10)
      )
      |> EdgeDB.start_link()

    generation_config = Application.get_env(:edgedb, :generation)

    if Keyword.keyword?(generation_config) do
      do_modules_generation(client, generation_config, silent?)
    else
      Enum.reduce_while(generation_config, {:ok, %{}}, fn config, {:ok, files} ->
        case do_modules_generation(client, config, silent?) do
          {:ok, new_files} ->
            {:cont, {:ok, Map.merge(files, new_files)}}

          error ->
            {:halt, error}
        end
      end)
    end
  end

  defp do_modules_generation(client, config, silent?) do
    queries_path = Keyword.fetch!(config, :queries_path)

    query_files =
      [queries_path, "**", "*.edgeql"]
      |> Path.join()
      |> Path.wildcard()

    DBConnection.run(
      client,
      fn conn ->
        Enum.reduce_while(query_files, {:ok, %{}}, fn query_file, {:ok, files} ->
          case generate_module_for_query_file(conn, config, query_file, silent?) do
            {:ok, elixir_file} ->
              files = Map.put(files, query_file, elixir_file)
              {:cont, {:ok, files}}

            {:error, error} ->
              {:halt, {:error, {query_file, error}}}
          end
        end)
      end,
      timeout: :infinity
    )
  end

  defp generate_module_for_query_file(conn, config, query_file, silent?) do
    queries_path = Keyword.fetch!(config, :queries_path)
    output_path = Keyword.get(config, :output_path, @default_output)
    module_prefix = config[:module_prefix]

    statement = File.read!(query_file)

    query_name =
      query_file
      |> Path.rootname()
      |> Path.basename()

    query_parts =
      query_file
      |> Path.dirname()
      |> Path.relative_to(queries_path)
      |> Path.split()
      |> Enum.reject(&(&1 == "."))

    file_name =
      [output_path, query_parts, query_name]
      |> List.flatten()
      |> Path.join()

    file_name = "#{file_name}.edgeql.ex"

    if not silent? do
      IO.puts("Generating #{file_name} from #{query_file}")
    end

    module_parts =
      if module_prefix do
        List.flatten([Module.split(module_prefix), query_parts, query_name])
      else
        List.flatten([query_parts, query_name])
      end

    query = %EdgeDB.Query{
      statement: statement,
      required: true,
      inline_type_names: true,
      __file__: query_file
    }

    module_name = Enum.map_join(module_parts, ".", &Macro.camelize/1)

    with {:ok, query} <- DBConnection.prepare(conn, query, edgeql_state: %EdgeDB.Client.State{}),
         {:ok, elixir_file} <- generate_elixir_module(query, query_file, file_name, module_name) do
      {:ok, elixir_file}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp generate_elixir_module(%EdgeDB.Query{} = query, query_file, output_file, module_name) do
    reset_types()

    input_codec = CodecStorage.get(query.codec_storage, query.input_codec)
    output_codec = CodecStorage.get(query.codec_storage, query.output_codec)

    {args, positional?} = input_codec_to_args(input_codec, query.codec_storage)
    raw_shape = output_codec_to_shape(query, output_codec, query.codec_storage)
    raw_schema = shape_to_schema(raw_shape)

    rendered_shape =
      render_shape(
        shape: raw_shape,
        render_shape: &render_shape/1,
        render_builtin: &render_builtin/1,
        render_object: &render_object/1,
        render_set: &render_set/1
      )

    rendered_schema =
      if raw_schema do
        render_schema(
          schema: raw_schema,
          render_schema: &render_schema/1
        )
      else
        nil
      end

    generated_module =
      generate_query_module(
        query_file: query_file,
        module_name: module_name,
        types: types(),
        shape: rendered_shape,
        schema: rendered_schema,
        query_function: @cardinality_to_function[query.result_cardinality],
        should_render_type_for_shape: complex_shape?(raw_shape),
        result_type: (complex_shape?(raw_shape) && "result()") || rendered_shape,
        query: %{
          statement: query.statement,
          has_positional_args: positional? and length(args) != 0,
          has_named_args: not positional? and length(args) != 0,
          args: args
        }
      )

    output_file
    |> Path.dirname()
    |> File.mkdir_p!()

    generated_module
    |> Code.format_string!()
    |> then(&File.write!(output_file, [&1, "\n"]))

    {:ok, output_file}
  end

  defp input_codec_to_args(%Codecs.Null{}, _codec_storage) do
    {[], false}
  end

  defp input_codec_to_args(%Codecs.Object{} = codec, codec_storage) do
    positional? =
      Enum.reduce_while(codec.shape_elements, false, fn %{name: name}, positional? ->
        case Integer.parse(name) do
          {_arg_index, ""} ->
            {:halt, true}

          _other ->
            {:cont, positional?}
        end
      end)

    args =
      codec.shape_elements
      |> Enum.zip(codec.codecs)
      |> Enum.reduce([], fn {element, codec}, args ->
        codec = CodecStorage.get(codec_storage, codec)

        %{typespec: typespec} = codec_to_shape(codec, codec_storage)

        typespec =
          case element.cardinality do
            :at_most_one ->
              "#{typespec} | nil"

            _other ->
              typespec
          end

        [%{name: element.name, typespec: typespec} | args]
      end)
      |> Enum.reverse()

    {args, positional?}
  end

  defp output_codec_to_shape(%EdgeDB.Query{} = query, codec, codec_storage) do
    Map.merge(
      %{
        is_list: query.result_cardinality in [:many, :at_least_one],
        is_optional: query.result_cardinality == :at_most_one
      },
      codec_to_shape(codec, codec_storage)
    )
  end

  defp codec_to_shape(%Codecs.Object{} = codec, codec_storage) do
    fields =
      codec.shape_elements
      |> Enum.zip(codec.codecs)
      |> Enum.reject(fn {%{flags: flags}, _codec} ->
        Bitwise.band(flags, @field_is_implicit) != 0
      end)
      |> Enum.with_index()
      |> Enum.reduce([], fn {{%{flags: flags} = element, codec}, index}, fields ->
        codec = CodecStorage.get(codec_storage, codec)
        optional? = element.cardinality == :at_most_one
        list? = element.cardinality in [:many, :at_least_one]

        link_property? = Bitwise.band(flags, @field_is_link_property) != 0

        field_shape =
          Map.merge(
            %{
              is_list: list?,
              is_optional: optional?,
              is_link_property: link_property?,
              index: index
            },
            codec_to_shape(codec, codec_storage)
          )

        [{element.name, field_shape} | fields]
      end)
      |> Enum.reverse()

    %{type: :object, fields: fields}
  end

  defp codec_to_shape(%Codecs.Set{} = codec, codec_storage) do
    codec = CodecStorage.get(codec_storage, codec.codec)
    element_shape = codec_to_shape(codec, codec_storage)
    %{type: :set, is_list: true, shape: element_shape}
  end

  defp codec_to_shape(%Codecs.UUID{}, _codec_storage) do
    typename = "uuid()"
    uuid_typespec = @builtin_scalars_to_typespecs[Codecs.UUID]
    register_typespec(typename, uuid_typespec)
    %{type: :builtin, typespec: typename}
  end

  defp codec_to_shape(%Codecs.JSON{}, _codec_storage) do
    typename = "json()"
    json_typespec = @builtin_scalars_to_typespecs[Codecs.JSON]
    register_typespec(typename, json_typespec)
    %{type: :builtin, typespec: typename}
  end

  defp codec_to_shape(%Codecs.Duration{}, _codec_storage) do
    timex? = Application.get_env(:edgedb, :timex_duration, true)

    typename = "duration()"

    case Code.ensure_loaded?(Timex) do
      true when timex? ->
        {typedoc, typespec} = @builtin_scalars_to_typespecs[Codecs.Duration]
        register_typespec(typename, {typedoc, ["Timex.Duration.t()", typespec]})

      _other ->
        duration_typespec = @builtin_scalars_to_typespecs[Codecs.Duration]
        register_typespec(typename, duration_typespec)
    end

    %{type: :builtin, typespec: typename}
  end

  defp codec_to_shape(%Codecs.Vector{}, _codec_storage) do
    typename = "vector()"
    vector_typespec = @builtin_scalars_to_typespecs[Codecs.Vector]
    register_typespec(typename, vector_typespec)
    %{type: :builtin, typespec: typename}
  end

  defp codec_to_shape(%codec_name{}, _codec_storage) when codec_name in @scalar_codecs do
    %{type: :builtin, typespec: elem(@builtin_scalars_to_typespecs[codec_name], 1)}
  end

  defp codec_to_shape(%Codecs.Scalar{codec: subcodec, name: nil}, codec_storage) do
    %subcodec_name{} = CodecStorage.get(codec_storage, subcodec)
    {_typedoc, subcodec_typespec} = @builtin_scalars_to_typespecs[subcodec_name]
    %{type: :builtin, typespec: subcodec_typespec}
  end

  defp codec_to_shape(%Codecs.Scalar{codec: subcodec, name: type_name}, codec_storage) do
    %subcodec_name{} = CodecStorage.get(codec_storage, subcodec)

    full_type_name = full_name_to_typespec(type_name)
    {typedoc, subcodec_typespec} = @builtin_scalars_to_typespecs[subcodec_name]
    typedoc = "scalar type #{type_name} extending #{typedoc}"

    register_typespec(full_type_name, {typedoc, subcodec_typespec})

    %{type: :builtin, typespec: full_type_name}
  end

  defp codec_to_shape(%Codecs.Enum{name: type_name, members: members}, _codec_storage) do
    full_type_name = full_name_to_typespec(type_name)
    typedoc = "scalar type #{type_name} extending enum<#{Enum.join(members, ", ")}>"
    register_typespec(full_type_name, {typedoc, ["String.t()" | Enum.map(members, &":#{inspect(&1)}")]})
    %{type: :builtin, typespec: full_type_name}
  end

  defp codec_to_shape(%Codecs.Array{codec: subcodec}, codec_storage) do
    subcodec = CodecStorage.get(codec_storage, subcodec)
    %{typespec: typespec} = shape = codec_to_shape(subcodec, codec_storage)
    %{type: :builtin, typespec: "[#{typespec}]", element: shape}
  end

  defp codec_to_shape(%Codecs.Tuple{codecs: subcodecs}, codec_storage) do
    shapes =
      Enum.map(subcodecs, fn subcodec ->
        subcodec = CodecStorage.get(codec_storage, subcodec)
        codec_to_shape(subcodec, codec_storage)
      end)

    typespec = "{#{Enum.map_join(shapes, ", ", & &1.typespec)}}"
    %{type: :builtin, typespec: typespec, elements: shapes}
  end

  defp codec_to_shape(%Codecs.NamedTuple{codecs: subcodecs, elements: elements}, codec_storage) do
    shapes =
      subcodecs
      |> Enum.zip(elements)
      |> Enum.with_index()
      |> Enum.map(fn {{subcodec, element}, index} ->
        subcodec = CodecStorage.get(codec_storage, subcodec)
        shape = codec_to_shape(subcodec, codec_storage)
        Map.merge(%{name: element.name, index: index}, shape)
      end)

    map_elements =
      Enum.map_join(shapes, ", ", &":#{&1.name} => #{&1.typespec}, #{&1.index} => #{&1.typespec}")

    typespec = "%{#{map_elements}}"
    %{type: :builtin, typespec: typespec, elements: shapes}
  end

  defp codec_to_shape(%Codecs.Range{codec: subcodec}, codec_storage) do
    subcodec = CodecStorage.get(codec_storage, subcodec)
    %{typespec: typespec} = codec_to_shape(subcodec, codec_storage)
    %{type: :builtin, typespec: "EdgeDB.Range.t(#{typespec})"}
  end

  defp full_name_to_typespec(type_name) do
    type_name =
      type_name
      |> String.split("::", parts: 2)
      |> Enum.map_join("__", &Macro.underscore/1)

    "#{type_name}()"
  end

  defp complex_shape?(%{type: :builtin}) do
    false
  end

  defp complex_shape?(%{type: :set, shape: shape}) do
    complex_shape?(shape)
  end

  defp complex_shape?(%{type: :object}) do
    true
  end

  defp shape_to_schema(%{type: :set, shape: shape}) do
    shape_to_schema(shape)
  end

  defp shape_to_schema(%{type: :object, fields: fields}) do
    schema =
      fields
      |> Enum.map(fn {name, shape} ->
        case shape_to_schema(shape) do
          nil ->
            name

          shape ->
            {name, shape}
        end
      end)
      |> Enum.sort(:desc)

    case schema do
      [] ->
        nil

      schema ->
        schema
    end
  end

  defp shape_to_schema(%{type: :builtin, element: element}) do
    shape_to_schema(element)
  end

  defp shape_to_schema(%{type: :builtin, elements: elements}) do
    schema =
      elements
      |> Enum.map(fn
        %{name: name} = element ->
          case shape_to_schema(element) do
            nil ->
              name

            shape ->
              {name, shape}
          end

        element ->
          shape_to_schema(element)
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort(:desc)

    case schema do
      [] ->
        nil

      schema ->
        schema
    end
  end

  defp shape_to_schema(%{type: :builtin}) do
    nil
  end

  defp types do
    @types_tab
    |> :ets.tab2list()
    |> Enum.sort()
    |> Enum.reverse()
  end

  defp reset_types do
    :ets.new(@types_tab, [:named_table])
  rescue
    ArgumentError ->
      :ets.delete_all_objects(@types_tab)
  end

  defp register_typespec(type_name, {typedoc, typespecs}) when is_list(typespecs) do
    register_typespec(type_name, {typedoc, Enum.join(typespecs, "|")})
  end

  defp register_typespec(type_name, {typedoc, typespec}) do
    :ets.insert(@types_tab, {type_name, {typedoc, typespec}})
  end

  defp generate_query_module(assigns), do: render_query_template(assigns)

  defp render_shape(assigns),
    do: assigns |> render_shape_template() |> postprocess_render()

  defp render_schema(assigns),
    do: assigns |> render_schema_template() |> postprocess_render()

  defp render_builtin(assigns),
    do: assigns |> render_builtin_template() |> postprocess_render()

  defp render_object(assigns),
    do: assigns |> render_object_template() |> postprocess_render()

  defp render_set(assigns),
    do: assigns |> render_set_template() |> postprocess_render()

  defp postprocess_render(result),
    do: result |> String.split("\n") |> Enum.join(" ") |> String.trim()
end
