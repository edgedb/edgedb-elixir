defmodule EdgeDB.Protocol.Codecs.EmptyTuple do
  use EdgeDB.Protocol.Codec

  @empty_tuple_type_id UUID.from_string("00000000-0000-0000-0000-0000000000FF")

  defcodec(type: {})

  def new do
    encoder =
      create_encoder(fn _ ->
        <<0::int32>>
      end)

    decoder =
      create_decoder(fn <<0::int32>> ->
        {}
      end)

    %Codec{
      type_id: @empty_tuple_type_id,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end
end
