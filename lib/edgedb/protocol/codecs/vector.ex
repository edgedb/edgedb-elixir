defmodule EdgeDB.Protocol.Codecs.Vector do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("9565dd88-04f5-11ee-a691-0b6ebe179825")
  @name "ext::pgvector::vector"

  defstruct id: @id,
            name: @name

  @impl EdgeDB.Protocol.BaseScalarCodec
  def new do
    %__MODULE__{}
  end

  @impl EdgeDB.Protocol.BaseScalarCodec
  def id do
    @id
  end

  @impl EdgeDB.Protocol.BaseScalarCodec
  def name do
    @name
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Vector do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.Codec

  @max_pg_vector_dim Bitwise.bsl(1, 16) - 1

  @impl Codec
  def encode(_codec, [], _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as ext::pgvector::vector: " <>
              "vector must have at least 1 dimension"
          )
  end

  @impl Codec
  def encode(_codec, list, _codec_storage)
      when is_list(list) and length(list) > @max_pg_vector_dim do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as ext::pgvector::vector: " <>
              "too many elements to encode"
          )
  end

  @impl Codec
  def encode(_codec, list, _codec_storage) when is_list(list) do
    if Keyword.keyword?(list) do
      raise EdgeDB.InvalidArgumentError.new(
              "value can not be encoded as ext::pgvector::vector: " <>
                "keyword list can be encoded as ext::pgvector::vector: #{inspect(list)}"
            )
    end

    encoded_list = Enum.map(list, &<<&1::float32()>>)
    data = [[<<length(list)::int16(), 0::int16()>>] | encoded_list]
    [<<IO.iodata_length(data)::uint32()>> | data]
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as ext::pgvector::vector: #{inspect(value)}"
          )
  end

  @impl Codec
  def decode(_codec, <<length::uint32(), data::binary(length)>>, _codec_storage) do
    <<vector_length::int16(), rest::binary>> = data
    vector_length_size = vector_length * 4
    <<_reserved0::int16(), rest::binary(vector_length_size)>> = rest
    decode_vector_values(rest)
  end

  defp decode_vector_values(data) do
    decode_vector_values(data, [])
  end

  defp decode_vector_values(<<value::float32(), rest::binary>>, acc) do
    decode_vector_values(rest, [value | acc])
  end

  defp decode_vector_values(<<>>, acc) do
    Enum.reverse(acc)
  end
end
