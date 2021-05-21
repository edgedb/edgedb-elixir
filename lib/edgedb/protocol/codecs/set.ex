defmodule EdgeDB.Protocol.Codecs.Set do
  use EdgeDB.Protocol.Codec

  import EdgeDB.Protocol.Types.{
    Dimension,
    Envelope,
    ArrayElement
  }

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defcodec(type: EdgeDB.Set.t())

  @spec new(DataTypes.UUID.t(), Codec.t()) :: Codec.t()
  def new(type_id, codec) do
    encoder =
      create_encoder(fn %EdgeDB.Set{} ->
        raise EdgeDB.Protocol.Errors.InvalidArgumentError, "set cann't be encoded"
      end)

    decoder =
      create_decoder(fn
        <<0::int32, _reserved0::int32, _reserved1::int32, _rest::binary>> ->
          EdgeDB.Set.new()

        <<ndims::int32, _reserved0::int32, _reserved1::int32, rest::binary>> ->
          {dimensions, rest} = Types.Dimension.decode(ndims, rest)

          elements_count =
            Enum.reduce(dimensions, 0, fn dimension(upper: upper, lower: lower), acc ->
              acc + upper - lower + 1
            end)

          elements =
            case codec do
              %Codec{module: EdgeDB.Protocol.Codecs.Array} ->
                decode_envelopes(codec, elements_count, rest)

              _other_codec ->
                decode_elements(codec, elements_count, rest)
            end

          EdgeDB.Set.new(elements)
      end)

    %Codec{
      type_id: <<type_id::uuid>>,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end

  defp decode_envelopes(codec, elements_count, data) do
    {envelopes, <<>>} = Types.Envelope.decode(elements_count, data)

    Enum.into(envelopes, [], fn envelope(elements: elements) ->
      Enum.into(elements, [], fn array_element(data: data) ->
        codec.decoder.(data)
      end)
    end)
  end

  defp decode_elements(codec, elements_count, data) do
    {raw_elements, <<>>} = Types.ArrayElement.decode(elements_count, data)

    Enum.into(raw_elements, [], fn array_element(data: data) ->
      codec.decoder.(data)
    end)
  end
end
