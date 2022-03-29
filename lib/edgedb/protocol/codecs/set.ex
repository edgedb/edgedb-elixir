defmodule EdgeDB.Protocol.Codecs.Set do
  @moduledoc false

  alias EdgeDB.Protocol.Codec

  defstruct [
    :id,
    :codec
  ]

  @spec new(Codec.id(), Codec.id()) :: Codec.t()
  def new(id, codec) do
    %__MODULE__{id: id, codec: codec}
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Set do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Types,
    CodecStorage,
    Codec,
    Codecs
  }

  @empty_set %EdgeDB.Set{__items__: []}

  @impl Codec
  def encode(_codec, %EdgeDB.Set{}, _codec_storage) do
    raise EdgeDB.Error.invalid_argument_error(
            "value can not be encoded as set: set encoding is not supported"
          )
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.Error.invalid_argument_error(
            "value can not be encoded as set: #{inspect(value)}"
          )
  end

  @impl Codec
  def decode(
        _codec,
        <<12::uint32, 0::int32, _reserved0::int32, _reserved1::int32>>,
        _codec_storage
      ) do
    @empty_set
  end

  @impl Codec
  def decode(
        %{codec: codec},
        <<length::uint32, data::binary(length)>>,
        codec_storage
      ) do
    <<ndims::int32, _reserved0::int32, _reserved1::int32, rest::binary>> = data
    codec = CodecStorage.get(codec_storage, codec)

    {dimensions, rest} = decode_dimension_list(rest, ndims, [])
    element_count = Enum.reduce(dimensions, 0, &(&2 + &1.upper - &1.lower + 1))

    elements =
      case codec do
        %Codecs.Array{} ->
          decode_envelope_list(rest, codec, codec_storage, element_count, [])

        _other ->
          {elements, <<>>} = decode_element_list(rest, codec, codec_storage, element_count, [])
          elements
      end

    %EdgeDB.Set{__items__: elements}
  end

  defp decode_dimension_list(<<data::binary>>, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_dimension_list(<<data::binary>>, count, acc) do
    <<upper::int32, lower::int32, rest::binary>> = data
    decode_dimension_list(rest, count - 1, [%Types.Dimension{upper: upper, lower: lower} | acc])
  end

  defp decode_envelope_list(<<>>, _codec, _codec_storage, 0, acc) do
    Enum.reverse(acc)
  end

  defp decode_envelope_list(
         <<length::int32, 1::int32, _reserved::int32, rest::binary>>,
         codec,
         codec_storage,
         count,
         acc
       ) do
    {elements, rest} = decode_element_list(rest, codec, codec_storage, length, [])

    decode_element_list(rest, codec, codec_storage, count - 1, [
      %Types.Envelope{elements: elements} | acc
    ])
  end

  defp decode_element_list(<<data::binary>>, _codec, _codec_storage, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_element_list(
         <<length::int32, data::binary(length), rest::binary>>,
         codec,
         codec_storage,
         count,
         acc
       ) do
    element = Codec.decode(codec, <<length::uint32, data::binary>>, codec_storage)
    decode_element_list(rest, codec, codec_storage, count - 1, [element | acc])
  end
end
