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
  def encode(%{codecs: codecs}, tuple, codec_storage)
      when is_tuple(tuple) and tuple_size(tuple) == length(codecs) do
    elements =
      codecs
      |> Enum.map(&CodecStorage.get(codec_storage, &1))
      |> Enum.with_index()
      |> Enum.map(fn
        {codec, idx} ->
          element = elem(tuple, idx)

          if is_nil(element) do
            <<0::int32, -1::int32>>
          else
            Codec.encode(codec, element, codec_storage)
          end
      end)

    [<<IO.iodata_length(elements)::int32>> | elements]
  end

  @impl Codec
  def encode(%{codecs: codecs}, tuple, _codec_storage) when is_tuple(tuple) do
    expected_length = length(codecs)
    passed_length = tuple_size(tuple)

    raise EdgeDB.Error.invalid_argument_error(
            "value can not be encoded as tuple: mismatched tuple size: expected #{expected_length}, got #{passed_length}"
          )
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.Error.invalid_argument_error(
            "value can not be encoded as tuple: #{inspect(value)}"
          )
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
