defmodule EdgeDB.Protocol.Codecs.Tuple do
  @moduledoc false

  alias EdgeDB.Protocol.Codec

  defstruct [
    :id,
    :codecs
  ]

  @spec new(Codec.id(), list(Codec.id())) :: Codec.t()
  def new(id, codecs) do
    %__MODULE__{id: id, codecs: codecs}
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Tuple do
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
  def decode(%{codecs: codecs}, <<_length::uint32, nelems::int32, data::binary>>, codec_storage) do
    codecs = Enum.map(codecs, &CodecStorage.get(codec_storage, &1))
    elements = decode_element_list(data, codecs, codec_storage, nelems, [])
    List.to_tuple(elements)
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
    element = Codec.decode(codec, <<length::int32, data::binary>>, codec_storage)
    decode_element_list(rest, codecs, codec_storage, count - 1, [element | acc])
  end
end
