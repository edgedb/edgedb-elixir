defmodule EdgeDB.Protocol.Codecs.EmptyTuple do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Datatypes

  @empty_tuple_type_id Datatypes.UUID.from_string("00000000-0000-0000-0000-0000000000FF")

  defcodec(type: {})

  @spec new() :: Codec.t()
  def new do
    encoder = create_encoder(&encode_empty_tuple/1)
    decoder = create_decoder(&decode_empty_tuple/1)

    %Codec{
      type_id: @empty_tuple_type_id,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end

  @spec encode_empty_tuple(any()) :: bitstring()
  def encode_empty_tuple(_instance) do
    <<0::int32>>
  end

  @spec decode_empty_tuple(bitstring()) :: t()
  def decode_empty_tuple(<<0::int32>>) do
    {}
  end
end
