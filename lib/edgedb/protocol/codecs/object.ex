defmodule EdgeDB.Protocol.Codecs.Object do
  @moduledoc false

  alias EdgeDB.Protocol.{
    Codec,
    Types
  }

  defstruct [
    :id,
    :shape_elements,
    :codecs
  ]

  @spec new(Codec.id(), list(Types.ShapeElement.t()), list(Codec.id())) :: Codec.t()
  def new(id, shape_elements, codecs) do
    %__MODULE__{id: id, shape_elements: shape_elements, codecs: codecs}
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
  def encode(_codec, %EdgeDB.Object{}, _codec_storage) do
    raise EdgeDB.Error.invalid_argument_error(
            "value can not be encoded as object: object encoding is not supported"
          )
  end

  @impl Codec
  def encode(%{shape_elements: elements, codecs: codecs}, list, codec_storage)
      when is_list(list) and length(list) == length(elements) do
    map =
      if Keyword.keyword?(list) do
        transform_into_string_map(list)
      else
        transform_into_indexed_string_map(list)
      end

    verify_all_members_passed!(map, elements)
    codecs = Enum.map(codecs, &CodecStorage.get(codec_storage, &1))

    values =
      elements
      |> Enum.zip(codecs)
      |> Enum.map(fn {%{name: name, cardinality: cardinality}, codec} ->
        value = map[name]

        if is_nil(value) and (cardinality == :one or cardinality == :at_least_one) do
          raise EdgeDB.Error.invalid_argument_error(
                  "argument #{inspect(name)} is required, but received nil"
                )
        end

        {value, codec}
      end)
      |> Enum.map(fn
        {nil, _codec} ->
          <<0::int32, -1::int32>>

        {value, codec} ->
          [<<0::int32>> | Codec.encode(codec, value, codec_storage)]
      end)

    data = [<<length(values)::int32>> | values]
    [<<IO.iodata_length(data)::uint32>> | data]
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.Error.invalid_argument_error(
            "value can not be encoded as object: #{inspect(value)}"
          )
  end

  @impl Codec
  def decode(
        %{shape_elements: elements, codecs: codecs},
        <<length::uint32, data::binary(length)>>,
        codec_storage
      ) do
    <<nelems::int32, rest::binary>> = data
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

  defp transform_into_string_map(list) do
    Enum.into(list, %{}, fn
      {key, value} when is_atom(key) ->
        {to_string(key), value}

      {key, value} when is_binary(key) ->
        {key, value}
    end)
  end

  defp transform_into_indexed_string_map(list) do
    list
    |> Enum.with_index()
    |> Enum.into(%{}, fn {value, index} ->
      {to_string(index), value}
    end)
  end

  defp verify_all_members_passed!(map, elements) do
    passed_keys =
      map
      |> Map.keys()
      |> MapSet.new()

    required_keys = Enum.into(elements, MapSet.new(), & &1.name)
    missed_keys = MapSet.difference(required_keys, passed_keys)
    extra_keys = MapSet.difference(passed_keys, required_keys)

    if MapSet.size(missed_keys) != 0 or MapSet.size(extra_keys) != 0 do
      err = make_wrong_elements_error_message(required_keys, passed_keys, missed_keys, extra_keys)
      raise EdgeDB.Error.invalid_argument_error("value can not be encoded as object: #{err}")
    end

    :ok
  end

  defp make_wrong_elements_error_message(required_keys, passed_keys, missed_keys, extra_keys) do
    error_message =
      "exptected #{MapSet.to_list(required_keys)} keys in named tuple, " <>
        "got #{MapSet.to_list(passed_keys)}"

    error_message =
      if MapSet.size(missed_keys) != 0 do
        "#{error_message}, missed #{MapSet.to_list(missed_keys)}"
      else
        error_message
      end

    if MapSet.size(extra_keys) != 0 do
      "#{error_message}, missed #{MapSet.to_list(extra_keys)}"
    else
      error_message
    end
  end

  defp decode_element_list(<<>>, [], [], _codec_storage, 0, fields, order) do
    {fields, Enum.reverse(order)}
  end

  defp decode_element_list(
         <<_reserved::int32, -1::int32, rest::binary>>,
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

    field = %EdgeDB.Object.Field{
      name: name,
      value: @empty_set,
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
         <<_reserved::int32, length::int32, data::binary(length), rest::binary>>,
         [codec | codecs],
         [element | elements],
         codec_storage,
         count,
         fields,
         order
       ) do
    value = Codec.decode(codec, <<length::uint32, data::binary>>, codec_storage)

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
