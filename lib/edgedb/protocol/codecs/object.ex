defmodule EdgeDB.Protocol.Codecs.Object do
  @moduledoc false

  alias EdgeDB.Protocol.{
    Codec,
    CodecStorage,
    Types
  }

  defstruct [
    :id,
    :name,
    :shape_elements,
    :codecs,
    :is_sparse
  ]

  @spec new(
          Codec.id(),
          String.t() | nil,
          list(Types.ShapeElement.t()),
          list(Codec.id()),
          boolean()
        ) :: Codec.t()
  def new(id, name, shape_elements, codecs, sparse?) do
    %__MODULE__{
      id: id,
      name: name,
      shape_elements: shape_elements,
      codecs: codecs,
      is_sparse: sparse?
    }
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Object do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Codec,
    CodecStorage
  }

  @empty_set %EdgeDB.Set{__items__: []}
  @field_is_implicit Bitwise.bsl(1, 0)
  @field_is_link_property Bitwise.bsl(1, 1)
  @field_is_link Bitwise.bsl(1, 2)

  @impl Codec
  def encode(%{is_sparse: true} = codec, session, codec_storage) do
    do_sparse_object_encoding(codec, session, codec_storage)
  end

  @impl Codec
  def encode(_codec, %EdgeDB.Object{}, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as object: objects encoding is not supported"
          )
  end

  # maybe worth adding in future, but for now it's not allowed
  @impl Codec
  def encode(_codec, %{__struct__: _struct_mod}, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as object: structs encoding is not supported"
          )
  end

  @impl Codec
  def encode(%{shape_elements: elements} = codec, arguments, codec_storage)
      when is_list(arguments) and length(arguments) == length(elements) do
    if Keyword.keyword?(arguments) do
      ensure_input_params_are_named!(elements)
    end

    do_object_encoding(codec, arguments, codec_storage)
  end

  @impl Codec
  def encode(%{shape_elements: elements} = codec, arguments, codec_storage)
      when is_map(arguments) and map_size(arguments) == length(elements) do
    ensure_input_params_are_named!(elements)
    do_object_encoding(codec, arguments, codec_storage)
  end

  @impl Codec
  def encode(%{shape_elements: elements}, arguments, _codec_storage)
      when is_list(arguments) or is_map(arguments) do
    arguments
    |> transform_arguments()
    |> raise_wrong_arguments_error!(elements)
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new("value can not be encoded as object: #{inspect(value)}")
  end

  @impl Codec
  def decode(
        %{shape_elements: elements, codecs: codecs},
        <<length::uint32(), data::binary(length)>>,
        codec_storage
      ) do
    <<nelems::int32(), rest::binary>> = data
    codecs = Enum.map(codecs, &CodecStorage.get(codec_storage, &1))
    {fields, order} = decode_element_list(rest, codecs, elements, codec_storage, nelems, %{}, [])

    id =
      if field = fields["id"] do
        field.value
      else
        nil
      end

    type_id =
      if field = fields["__tid__"] do
        field.value
      else
        nil
      end

    %EdgeDB.Object{
      id: id,
      __tid__: type_id,
      __fields__: fields,
      __order__: order
    }
  end

  @spec transform_arguments(list() | Keyword.t() | map()) :: %{String.t() => term()}
  def transform_arguments(arguments) do
    cond do
      is_map(arguments) ->
        transform_list_into_string_map(arguments)

      Keyword.keyword?(arguments) ->
        transform_list_into_string_map(arguments)

      is_list(arguments) ->
        transform_list_into_indexed_string_map(arguments)
    end
  end

  @spec raise_wrong_arguments_error!(map(), list()) :: no_return()
  def raise_wrong_arguments_error!(arguments, elements) do
    passed_keys =
      arguments
      |> Map.keys()
      |> MapSet.new()

    required_keys = Enum.into(elements, MapSet.new(), & &1.name)
    missed_keys = MapSet.difference(required_keys, passed_keys)
    extra_keys = MapSet.difference(passed_keys, required_keys)

    error_message =
      if MapSet.size(required_keys) == 0 do
        "expected nothing"
      else
        "expected #{inspect(MapSet.to_list(required_keys))} keys"
      end

    error_message =
      cond do
        MapSet.size(required_keys) == 0 and MapSet.size(passed_keys) == 0 ->
          error_message

        MapSet.size(required_keys) != 0 and MapSet.size(passed_keys) == 0 ->
          "#{error_message}, passed nothing"

        true ->
          "#{error_message}, passed #{inspect(MapSet.to_list(passed_keys))} keys"
      end

    error_message =
      if MapSet.size(missed_keys) != 0 do
        "#{error_message}, missed #{inspect(MapSet.to_list(missed_keys))} keys"
      else
        error_message
      end

    error_message =
      if MapSet.size(extra_keys) != 0 do
        "#{error_message}, passed extra #{inspect(MapSet.to_list(extra_keys))} keys"
      else
        error_message
      end

    raise EdgeDB.QueryArgumentError.new(error_message)
  end

  defp ensure_input_params_are_named!(elements) do
    for element <- elements do
      case Integer.parse(element.name) do
        :error ->
          :ok

        {_pos_index, _rest} ->
          raise EdgeDB.QueryArgumentError.new(
                  "only named arguments are allowed to use with parameters in map/keyword list, " <>
                    "to use positional arguments pass parameters as plain list"
                )
      end
    end
  end

  defp do_object_encoding(%{shape_elements: elements, codecs: codecs}, arguments, codec_storage) do
    values =
      arguments
      |> process_arguments(elements, codecs, codec_storage)
      |> Enum.with_index()
      |> Enum.reduce([], fn
        {{:__edgedb_skip__, _codec}, _index}, acc ->
          acc

        {{nil, _codec}, index}, acc ->
          [[<<index::int32(), -1::int32()>>] | acc]

        {{value, codec}, index}, acc ->
          [[<<index::int32()>> | Codec.encode(codec, value, codec_storage)] | acc]
      end)
      |> Enum.reverse()

    data = [<<length(values)::int32()>> | values]
    [<<IO.iodata_length(data)::uint32()>> | data]
  end

  defp do_sparse_object_encoding(
         %{shape_elements: elements} = codec,
         %{} = object,
         codec_storage
       ) do
    items =
      Enum.into(elements, %{}, fn element ->
        case Access.fetch(object, element.name) do
          {:ok, value} ->
            {element.name, value}

          :error ->
            {element.name, :__edgedb_skip__}
        end
      end)

    do_object_encoding(codec, items, codec_storage)
  end

  defp process_arguments(arguments, elements, codecs, codec_storage) do
    arguments = transform_arguments(arguments)
    codecs = Enum.map(codecs, &CodecStorage.get(codec_storage, &1))

    elements
    |> Enum.zip(codecs)
    |> Enum.map(fn {%{name: name, cardinality: cardinality}, codec} ->
      value =
        case Map.fetch(arguments, name) do
          {:ok, value} ->
            value

          :error ->
            raise_wrong_arguments_error!(arguments, elements)
        end

      if is_nil(value) and (cardinality == :one or cardinality == :at_least_one) do
        raise EdgeDB.InvalidArgumentError.new(
                "argument #{inspect(name)} is required, but received nil"
              )
      end

      {value, codec}
    end)
  end

  defp transform_list_into_string_map(list) do
    Enum.into(list, %{}, fn
      {key, value} when is_atom(key) ->
        {to_string(key), value}

      {key, value} when is_binary(key) ->
        {key, value}
    end)
  end

  defp transform_list_into_indexed_string_map(list) do
    list
    |> Enum.with_index()
    |> Enum.into(%{}, fn {value, index} ->
      {to_string(index), value}
    end)
  end

  defp decode_element_list(<<>>, [], [], _codec_storage, 0, fields, order) do
    {fields, Enum.reverse(order)}
  end

  defp decode_element_list(
         <<_reserved::int32(), -1::int32(), rest::binary>>,
         [_codec | codecs],
         [element | elements],
         codec_storage,
         count,
         fields,
         order
       ) do
    name =
      if link_property?(element) do
        "@#{element.name}"
      else
        element.name
      end

    single_property? =
      element.cardinality in [:at_most_one, :one] and
        (link_property?(element) or not link?(element))

    value =
      if single_property? do
        nil
      else
        @empty_set
      end

    field = %EdgeDB.Object.Field{
      name: name,
      value: value,
      is_link: link?(element),
      is_link_property: link_property?(element),
      is_implicit: implicit?(element)
    }

    decode_element_list(
      rest,
      codecs,
      elements,
      codec_storage,
      count - 1,
      Map.put(fields, field.name, field),
      [name | order]
    )
  end

  defp decode_element_list(
         <<_reserved::int32(), length::int32(), data::binary(length), rest::binary>>,
         [codec | codecs],
         [element | elements],
         codec_storage,
         count,
         fields,
         order
       ) do
    value = Codec.decode(codec, <<length::uint32(), data::binary>>, codec_storage)

    name =
      if link_property?(element) do
        "@#{element.name}"
      else
        element.name
      end

    field = %EdgeDB.Object.Field{
      name: name,
      value: value,
      is_link: link?(element),
      is_link_property: link_property?(element),
      is_implicit: implicit?(element)
    }

    decode_element_list(
      rest,
      codecs,
      elements,
      codec_storage,
      count - 1,
      Map.put(fields, field.name, field),
      [name | order]
    )
  end

  defp link?(%{flags: flags}) do
    Bitwise.band(flags, @field_is_link) != 0
  end

  defp link_property?(%{flags: flags}) do
    Bitwise.band(flags, @field_is_link_property) != 0
  end

  defp implicit?(%{flags: flags}) do
    Bitwise.band(flags, @field_is_implicit) != 0
  end
end
