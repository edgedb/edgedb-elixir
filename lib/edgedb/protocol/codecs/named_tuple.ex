defmodule EdgeDB.Protocol.Codecs.NamedTuple do
  @moduledoc false

  alias EdgeDB.Protocol.{
    Codec,
    Types
  }

  defstruct [
    :id,
    :elements,
    :codecs
  ]

  @spec new(Codec.id(), list(Types.TupleElement.t()), list(Codec.id())) :: Codec.t()
  def new(id, elements, codecs) do
    %__MODULE__{id: id, elements: elements, codecs: codecs}
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.NamedTuple do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Codec,
    CodecStorage
  }

  @empty_set %EdgeDB.Set{__items__: []}

  @impl Codec
  def encode(%{elements: elements, codecs: codecs}, map, codec_storage)
      when is_map(map) and map_size(map) == length(codecs) do
    map = transform_into_string_map(map)

    verify_all_members_passed!(map, elements)

    elements =
      codecs
      |> Enum.map(&CodecStorage.get(codec_storage, &1))
      |> Enum.zip(elements)
      |> Enum.map(fn {codec, element} ->
        value = map[element.name]

        if is_nil(value) do
          <<0::int32, -1::int32>>
        else
          [<<0::int32>> | Codec.encode(codec, value, codec_storage)]
        end
      end)

    data = [<<length(elements)::int32>> | elements]
    [<<IO.iodata_length(data)::uint32>> | data]
  end

  @impl Codec
  def encode(%{codecs: codecs} = codec, list, codec_storage)
      when is_list(list) and length(list) == length(codecs) do
    if not Keyword.keyword?(list) do
      raise EdgeDB.Error.invalid_argument_error(
              "value can not be encoded as named tuple: plain list can not encoded, use keyword list"
            )
    end

    map = Enum.into(list, %{})
    encode(codec, map, codec_storage)
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.Error.invalid_argument_error(
            "value can not be encoded as named tuple: #{inspect(value)}"
          )
  end

  @impl Codec
  def decode(
        %{elements: elements, codecs: codecs},
        <<length::uint32, data::binary(length)>>,
        codec_storage
      ) do
    <<nelems::int32, rest::binary>> = data
    codecs = Enum.map(codecs, &CodecStorage.get(codec_storage, &1))
    values = decode_element_list(rest, codecs, codec_storage, nelems, [])
    elements = Enum.map(elements, & &1.name)

    map =
      elements
      |> Enum.zip(values)
      |> Enum.into(%{})

    ordering =
      elements
      |> Enum.with_index()
      |> Enum.into(%{}, fn {element, idx} ->
        {idx, element}
      end)

    %EdgeDB.NamedTuple{__items__: map, __fields_ordering__: ordering}
  end

  defp transform_into_string_map(value) do
    Enum.into(value, %{}, fn
      {key, value} when is_atom(key) ->
        {to_string(key), value}

      {key, value} when is_binary(key) ->
        {key, value}
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
      EdgeDB.Error.invalid_argument_error("value can not be encoded as named tuple: #{err}")
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

  defp decode_element_list(<<>>, [], _codec_storage, 0, acc) do
    Enum.reverse(acc)
  end

  defp decode_element_list(
         <<_reserved::int32, -1::int32, rest::binary>>,
         [_codec | codecs],
         codec_storage,
         count,
         acc
       ) do
    decode_element_list(rest, codecs, codec_storage, count - 1, [@empty_set | acc])
  end

  defp decode_element_list(
         <<_reserved::int32, length::int32, data::binary(length), rest::binary>>,
         [codec | codecs],
         codec_storage,
         count,
         acc
       ) do
    element = Codec.decode(codec, <<length::uint32, data::binary>>, codec_storage)
    decode_element_list(rest, codecs, codec_storage, count - 1, [element | acc])
  end
end
