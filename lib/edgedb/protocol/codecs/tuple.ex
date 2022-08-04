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

  # tuples encoding is an internal part of the protocol
  # i.e. users cannot pass them as query arguments and they will receive
  # appropriate error before doing that.
  # so any error that may occur here is a client bug
  @impl Codec
  def encode(%{codecs: codecs}, tuple, codec_storage) when is_tuple(tuple) do
    if length(codecs) != tuple_size(tuple) do
      raise EdgeDB.InternalClientError.new(
              "unable to encode tuple: " <>
                "expected #{length(codecs)} elements, got: #{tuple_size(tuple)}"
            )
    end

    codecs = Enum.map(codecs, &CodecStorage.get(codec_storage, &1))

    values =
      tuple
      |> Tuple.to_list()
      |> Enum.zip(codecs)
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
