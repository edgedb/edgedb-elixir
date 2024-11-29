defmodule EdgeDB.Protocol.Codecs.MultiRange do
  @moduledoc false

  alias EdgeDB.Protocol.Codec

  defstruct [
    :id,
    :name,
    :codec
  ]

  @spec new(Codec.id(), String.t() | nil, Codec.t()) :: Codec.t()
  def new(id, name, codec) do
    %__MODULE__{id: id, name: name, codec: codec}
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.MultiRange do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Codec,
    Codecs
  }

  @impl Codec
  def encode(%{codec: codec}, %EdgeDB.MultiRange{ranges: ranges}, codec_storage) do
    range_codec = %Codecs.Range{codec: codec}

    data = [
      <<length(ranges)::uint32()>>,
      Enum.map(ranges, &Codec.encode(range_codec, &1, codec_storage))
    ]

    [<<IO.iodata_length(data)::uint32()>> | data]
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as multirange: #{inspect(value)}"
          )
  end

  @impl Codec
  def decode(
        %{codec: codec},
        <<length::uint32(), data::binary(length)>>,
        codec_storage
      ) do
    range_codec = %Codecs.Range{codec: codec}

    <<ranges_count::uint32(), rest::binary>> = data
    {ranges, <<>>} = decode_range_list(rest, range_codec, codec_storage, ranges_count, [])
    %EdgeDB.MultiRange{ranges: ranges}
  end

  defp decode_range_list(<<data::binary>>, _codec, _codec_storage, 0, acc) do
    {Enum.reverse(acc), data}
  end

  defp decode_range_list(
         <<length::uint32(), data::binary(length), rest::binary>>,
         codec,
         codec_storage,
         count,
         acc
       ) do
    range = Codec.decode(codec, <<length::uint32(), data::binary>>, codec_storage)
    decode_range_list(rest, codec, codec_storage, count - 1, [range | acc])
  end
end
