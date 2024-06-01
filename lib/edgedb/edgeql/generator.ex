defmodule EdgeDB.EdgeQL.Generator do
  @moduledoc false

  alias EdgeDB.EdgeQL.Generator

  alias EdgeDB.Protocol.{
    Codecs,
    CodecStorage
  }

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
  @field_is_link Bitwise.bsl(1, 2)

  @types_tab :edgedb_edgeql_gen_types

  @default_output "./lib/"

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

    generation_config = Application.get_env(:edgedb, :generation, [])

    cond do
      generation_config == [] ->
        {:ok, []}

      Keyword.keyword?(generation_config) ->
        do_modules_generation(client, generation_config, silent?)

      true ->
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
      |> String.split(".")

    query_parts =
      query_file
      |> Path.dirname()
      |> Path.relative_to(queries_path)
      |> Path.split()
      |> Enum.reject(&(&1 == "."))

    file_name =
      [output_path, query_parts, "#{Enum.join(query_name, ".")}.edgeql.ex"]
      |> List.flatten()
      |> Path.join()

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
         {:ok, elixir_file} <- generate_elixir_module(query, query_file, file_name, module_name, config) do
      {:ok, elixir_file}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp generate_elixir_module(%EdgeDB.Query{} = query, query_file, output_file, module_name, config) do
    reset_types()

    input_codec = CodecStorage.get(query.codec_storage, query.input_codec)
    output_codec = CodecStorage.get(query.codec_storage, query.output_codec)

    args = input_codec_to_args(input_codec, query.codec_storage, module_name, config)
    shape = output_codec_to_shape(query, output_codec, query.codec_storage, module_name, config)

    generated_module =
      Generator.Render.render(
        %Generator.Query{
          file: query_file,
          module: module_name,
          query: query.statement,
          types: types(),
          args: args,
          shape: shape,
          cardinality: query.result_cardinality
        },
        :module
      )

    output_file
    |> Path.dirname()
    |> File.mkdir_p!()

    generated_module
    |> Code.format_string!()
    |> then(&File.write!(output_file, [&1, "\n"]))

    {:ok, output_file}
  end

  defp input_codec_to_args(%Codecs.Null{}, _codec_storage, _module_name, _config) do
    %Generator.Args{is_empty: true}
  end

  defp input_codec_to_args(%Codecs.Object{} = codec, codec_storage, module_name, config) do
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

        [
          %Generator.Args.Arg{
            name: element.name,
            is_optional: element.cardinality == :at_most_one,
            type: handle_codec(codec, codec_storage, module_name, config)
          }
          | args
        ]
      end)
      |> Enum.reverse()

    %Generator.Args{
      args: args,
      is_empty: Enum.empty?(args),
      is_positional: positional?,
      is_named: not positional?
    }
  end

  defp output_codec_to_shape(%EdgeDB.Query{} = query, codec, codec_storage, module_name, config) do
    %Generator.Shape{
      is_multi: query.result_cardinality in [:many, :at_least_one],
      is_optional: query.result_cardinality == :at_most_one,
      type: handle_codec(codec, codec_storage, module_name, config)
    }
  end

  defp handle_codec(%Codecs.Object{} = codec, codec_storage, module_name, config) do
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
        multi? = element.cardinality in [:many, :at_least_one]

        field =
          if Bitwise.band(flags, @field_is_link) != 0 do
            %Generator.Object.Link{
              name: element.name,
              is_multi: multi?,
              is_optional: optional?,
              index: index,
              type: handle_codec(codec, codec_storage, module_name, config)
            }
          else
            %Generator.Object.Property{
              name: element.name,
              is_multi: multi?,
              is_optional: optional?,
              is_link_property: Bitwise.band(flags, @field_is_link_property) != 0,
              index: index,
              type: handle_codec(codec, codec_storage, module_name, config)
            }
          end

        [field | fields]
      end)
      |> Enum.reverse()

    links = Enum.filter(fields, &match?(%Generator.Object.Link{}, &1))
    properties = Enum.filter(fields, &match?(%Generator.Object.Property{}, &1))

    %Generator.Object{
      properties: properties,
      links: links
    }
  end

  defp handle_codec(%Codecs.Set{} = codec, codec_storage, module_name, config) do
    codec = CodecStorage.get(codec_storage, codec.codec)

    %Generator.Set{
      type: handle_codec(codec, codec_storage, module_name, config)
    }
  end

  defp handle_codec(%Codecs.UUID{}, _codec_storage, module_name, _config) do
    typename = "uuid()"
    uuid_typespec = @builtin_scalars_to_typespecs[Codecs.UUID]
    register_typespec(typename, uuid_typespec)
    %Generator.Scalar{typespec: typename, module: module_name}
  end

  defp handle_codec(%Codecs.JSON{}, _codec_storage, module_name, _config) do
    typename = "json()"
    json_typespec = @builtin_scalars_to_typespecs[Codecs.JSON]
    register_typespec(typename, json_typespec)
    %Generator.Scalar{typespec: typename, module: module_name}
  end

  defp handle_codec(%Codecs.Duration{}, _codec_storage, module_name, _config) do
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

    %Generator.Scalar{typespec: typename, module: module_name}
  end

  defp handle_codec(%Codecs.Vector{}, _codec_storage, module_name, _config) do
    typename = "vector()"
    vector_typespec = @builtin_scalars_to_typespecs[Codecs.Vector]
    register_typespec(typename, vector_typespec)
    %Generator.Scalar{typespec: typename, module: module_name}
  end

  defp handle_codec(%codec_name{}, _codec_storage, _module_name, _config) when codec_name in @scalar_codecs do
    %Generator.Scalar{typespec: elem(@builtin_scalars_to_typespecs[codec_name], 1)}
  end

  defp handle_codec(%Codecs.Scalar{codec: subcodec, name: nil}, codec_storage, _module_name, _config) do
    %subcodec_name{} = CodecStorage.get(codec_storage, subcodec)
    {_typedoc, subcodec_typespec} = @builtin_scalars_to_typespecs[subcodec_name]
    %{type: :builtin, typespec: subcodec_typespec}
    %Generator.Scalar{typespec: subcodec_typespec}
  end

  defp handle_codec(%Codecs.Scalar{codec: subcodec, name: type_name}, codec_storage, module_name, _config) do
    %subcodec_name{} = CodecStorage.get(codec_storage, subcodec)

    full_type_name = full_name_to_typespec(type_name)
    {typedoc, subcodec_typespec} = @builtin_scalars_to_typespecs[subcodec_name]
    typedoc = "scalar type #{type_name} extending #{typedoc}"

    register_typespec(full_type_name, {typedoc, subcodec_typespec})

    %Generator.Scalar{typespec: full_type_name, module: module_name}
  end

  defp handle_codec(%Codecs.Enum{name: type_name, members: members}, _codec_storage, module_name, config) do
    atomize? = Keyword.get(config, :atomize_enums, false)

    full_type_name = full_name_to_typespec(type_name)
    typedoc = "scalar type #{type_name} extending enum<#{Enum.join(members, ", ")}>"

    typespec =
      if atomize? do
        Enum.map(members, &":#{inspect(&1)}")
      else
        "String.t()"
      end

    register_typespec(
      full_type_name,
      {typedoc, typespec}
    )

    %Generator.Enum{typespec: full_type_name, module: module_name, members: members, atomize: atomize?}
  end

  defp handle_codec(%Codecs.Array{codec: subcodec}, codec_storage, module_name, config) do
    subcodec = CodecStorage.get(codec_storage, subcodec)
    type = handle_codec(subcodec, codec_storage, module_name, config)
    %Generator.Array{type: type}
  end

  defp handle_codec(%Codecs.Tuple{codecs: subcodecs}, codec_storage, module_name, config) do
    elements =
      Enum.map(subcodecs, fn subcodec ->
        subcodec = CodecStorage.get(codec_storage, subcodec)
        handle_codec(subcodec, codec_storage, module_name, config)
      end)

    %Generator.Tuple{elements: elements}
  end

  defp handle_codec(%Codecs.NamedTuple{codecs: subcodecs, elements: elements}, codec_storage, module_name, config) do
    elements =
      subcodecs
      |> Enum.zip(elements)
      |> Enum.map(fn {subcodec, element} ->
        subcodec = CodecStorage.get(codec_storage, subcodec)
        type = handle_codec(subcodec, codec_storage, module_name, config)
        %Generator.NamedTuple.Element{name: element.name, type: type}
      end)

    %Generator.NamedTuple{elements: elements}
  end

  defp handle_codec(%Codecs.Range{codec: subcodec}, codec_storage, module_name, config) do
    subcodec = CodecStorage.get(codec_storage, subcodec)
    type = handle_codec(subcodec, codec_storage, module_name, config)
    %Generator.Range{type: type}
  end

  defp handle_codec(%Codecs.MultiRange{codec: subcodec}, codec_storage, module_name, config) do
    subcodec = CodecStorage.get(codec_storage, subcodec)
    type = handle_codec(subcodec, codec_storage, module_name, config)

    %Generator.Range{type: type, is_multirange: true}
  end

  defp full_name_to_typespec(type_name) do
    type_name =
      type_name
      |> String.split("::")
      |> Enum.map_join("__", &Macro.underscore/1)

    "#{type_name}()"
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
end
