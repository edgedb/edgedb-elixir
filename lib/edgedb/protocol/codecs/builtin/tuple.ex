defmodule EdgeDB.Protocol.Codecs.Builtin.Tuple do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  defcodec(type: tuple())

  @spec new(Datatypes.UUID.t(), list(Codec.t())) :: Codec.t()
  def new(type_id, codecs) do
    encoder = create_encoder(&encode_tuple(&1, codecs))
    decoder = create_decoder(&decode_tuple(&1, codecs))

    %Codec{
      type_id: type_id,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end

  @spec encode_tuple(t() | list(), list(Codec.t())) :: iodata()

  def encode_tuple(instance, codecs)
      when is_tuple(instance) and tuple_size(instance) != length(codecs) do
    expected_length = length(codecs)
    passed_length = tuple_size(instance)

    raise EdgeDB.Error.invalid_argument_error(
            "wrong tuple size for encoding: expected #{expected_length}, passed #{passed_length}"
          )
  end

  def encode_tuple(instance, codecs) when is_tuple(instance) do
    instance
    |> Tuple.to_list()
    |> encode_tuple(codecs)
  end

  def encode_tuple(instance, codecs)
      when is_list(instance) and length(instance) != length(codecs) do
    expected_length = length(codecs)
    passed_length = length(instance)

    raise EdgeDB.Error.invalid_argument_error(
            "wrong tuple size for encoding: expected #{expected_length}, passed #{passed_length}"
          )
  end

  def encode_tuple(instance, codecs) when is_list(instance) do
    encoded_elements =
      instance
      |> Enum.zip(codecs)
      |> Enum.map(fn
        {nil, _codec} ->
          %Types.TupleElement{data: :empty_set}

        {value, codec} ->
          element_data = Codec.encode(codec, value)
          %Types.TupleElement{data: element_data}
      end)
      |> Types.TupleElement.encode(raw: true)

    encoded_length =
      encoded_elements
      |> length()
      |> Datatypes.Int32.encode()

    [encoded_length, encoded_elements]
  end

  @spec decode_tuple(bitstring(), list(Codec.t())) :: t()

  def decode_tuple(<<nelems::int32, data::binary>>, codecs) do
    {encoded_elements, <<>>} = Types.TupleElement.decode(nelems, data)

    encoded_elements
    |> Enum.zip(codecs)
    |> Enum.into([], fn {%Types.TupleElement{data: data}, codec} ->
      Codec.decode(codec, data)
    end)
    |> List.to_tuple()
  end
end
