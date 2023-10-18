defmodule EdgeDB.Protocol.Codecs.Array do
  @moduledoc false

  alias EdgeDB.Protocol.{
    Codec,
    Types
  }

  defstruct [
    :id,
    :name,
    :codec,
    :dimensions
  ]

  @spec new(Codec.id(), String.t() | nil, Codec.t(), list(Types.Dimension.t())) :: Codec.t()
  def new(id, name, codec, dimensions) do
    %__MODULE__{id: id, name: name, codec: codec, dimensions: dimensions}
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Array do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Types,
    CodecStorage,
    Codec
  }

  @impl Codec
  def encode(_codec, [], _codec_storage) do
    <<12::uint32(), 0::int32(), 0::int32(), 0::int32()>>
  end

  @impl Codec
  def encode(%{codec: codec, dimensions: dimensions}, list, codec_storage) when is_list(list) do
    if Keyword.keyword?(list) do
      raise EdgeDB.InvalidArgumentError.new(
              "value can not be encoded as array: keyword list can be encoded as named tuple: #{inspect(list)}"
            )
    end

    codec = CodecStorage.get(codec_storage, codec)
    ndims = length(dimensions)
    dimensions = encode_dimension_list(ndims, list)
    elements = encode_element_list(list, codec, codec_storage)

    data = [[<<ndims::int32(), 0::int32(), 0::int32()>> | dimensions] | elements]
    [<<IO.iodata_length(data)::uint32()>> | data]
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new("value can not be encoded as array: #{inspect(value)}")
  end

  @impl Codec
  def decode(
        _codec,
        <<12::uint32(), 0::int32(), _reserved0::int32(), _reserved1::int32()>>,
        _codec_storage
      ) do
    []
  end

  @impl Codec
  def decode(
        %{codec: codec},
        <<length::uint32(), data::binary(length)>>,
        codec_storage
      ) do
    <<ndims::int32(), _reserved0::int32(), _reserved1::int32(), rest::binary>> = data
    codec = CodecStorage.get(codec_storage, codec)
    {dimensions, rest} = decode_dimension_list(rest, ndims, [])
    element_count = Enum.reduce(dimensions, 0, &(&2 + &1.upper - &1.lower + 1))
    {elements, <<>>} = decode_element_list(rest, codec, codec_storage, element_count, [])

    elements
  end

  defp encode_dimension_list(1, list) do
    encode_dimension_list(0, [], [<<length(list)::int32(), 1::int32()>>])
  end

  defp encode_dimension_list(ndims, list) do
    encode_dimension_list(ndims, list, [])
  end

  defp encode_dimension_list(0, [], dimensions) do
    Enum.reverse(dimensions)
  end

  defp encode_dimension_list(ndims, [list | rest], dimensions) do
    encode_dimension_list(ndims - 1, rest, [<<length(list)::int32(), 1::int32()>> | dimensions])
  end

  defp encode_element_list(list, codec, codec_storage) do
    encode_element_list(list, [], codec, codec_storage)
  end

  defp encode_element_list([], elements, _codec, _codec_storage) do
    Enum.reverse(elements)
  end

  defp encode_element_list([element | rest], elements, codec, codec_storage) do
    encode_element_list(
      rest,
      [Codec.encode(codec, element, codec_storage) | elements],
      codec,
      codec_storage
    )
  end

  defp decode_dimension_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_dimension_list(<<data::binary>>, count, acc) do
    <<upper::int32(), lower::int32(), rest::binary>> = data
    decode_dimension_list(rest, count - 1, [%Types.Dimension{upper: upper, lower: lower} | acc])
  end

  defp decode_element_list(<<data::binary>>, _codec, _codec_storage, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_element_list(
         <<length::int32(), data::binary(length), rest::binary>>,
         codec,
         codec_storage,
         count,
         acc
       ) do
    element = Codec.decode(codec, <<length::int32(), data::binary>>, codec_storage)
    decode_element_list(rest, codec, codec_storage, count - 1, [element | acc])
  end
end
