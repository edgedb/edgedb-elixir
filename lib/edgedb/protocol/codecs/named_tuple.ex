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
  def encode(_codec, _value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new("tuples encoding is not supported by clients")
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
