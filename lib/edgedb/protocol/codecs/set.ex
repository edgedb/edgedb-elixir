defmodule EdgeDB.Protocol.Codecs.Set do
  use EdgeDB.Protocol.Codec

  import EdgeDB.Protocol.Types.{
    Dimension,
    Envelope,
    ArrayElement
  }

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes,
    Error,
    Types
  }

  defcodec(type: EdgeDB.Set.t())

  @spec new(Datatypes.UUID.t(), Codec.t()) :: Codec.t()
  def new(type_id, codec) do
    encoder = create_encoder(&encode_set(&1))
    decoder = create_decoder(&decode_set(&1, codec))

    %Codec{
      type_id: type_id,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end

  @spec encode_set(t()) :: no_return()
  def encode_set(%EdgeDB.Set{}) do
    raise Error.invalid_argument_error("set cann't be encoded")
  end

  @spec decode_set(bitstring(), Codec.t()) :: t()

  def decode_set(<<0::int32, _reserved0::int32, _reserved1::int32, _rest::binary>>, _codec) do
    EdgeDB.Set.new()
  end

  def decode_set(<<ndims::int32, _reserved0::int32, _reserved1::int32, rest::binary>>, codec) do
    {dimensions, rest} = Types.Dimension.decode(ndims, rest)

    elements_count =
      Enum.reduce(dimensions, 0, fn dimension(upper: upper, lower: lower), acc ->
        acc + upper - lower + 1
      end)

    elements =
      case codec do
        %Codec{module: Codecs.Array} ->
          decode_envelopes(codec, elements_count, rest)

        _other_codec ->
          decode_elements(codec, elements_count, rest)
      end

    EdgeDB.Set.new(elements)
  end

  defp decode_envelopes(codec, elements_count, data) do
    {envelopes, <<>>} = Types.Envelope.decode(elements_count, data)

    Enum.into(envelopes, [], fn envelope(elements: elements) ->
      Enum.into(elements, [], fn array_element(data: data) ->
        Codec.decode(codec, data)
      end)
    end)
  end

  defp decode_elements(codec, elements_count, data) do
    {raw_elements, <<>>} = Types.ArrayElement.decode(elements_count, data)

    Enum.into(raw_elements, [], fn array_element(data: data) ->
      Codec.decode(codec, data)
    end)
  end
end
