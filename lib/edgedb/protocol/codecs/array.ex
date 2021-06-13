defmodule EdgeDB.Protocol.Codecs.Array do
  use EdgeDB.Protocol.Codec

  import EdgeDB.Protocol.Types.{
    ArrayElement,
    Dimension
  }

  alias EdgeDB.Protocol.{
    Datatypes,
    Error,
    Types
  }

  @reserved0 0
  @reserved1 0
  @empty_list_iodata [
    Datatypes.Int32.encode(0),
    Datatypes.Int32.encode(@reserved0),
    Datatypes.Int32.encode(@reserved1)
  ]

  defcodec(type: list())

  @spec new(Datatypes.UUID.t(), list(integer()), Codec.t()) :: Codec.t()
  def new(type_id, dimensions, codec) do
    encoder = create_encoder(&encode_array(&1, dimensions, codec))
    decoder = create_decoder(&decode_array(&1, dimensions, codec))

    %Codec{
      type_id: type_id,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end

  @spec encode_array(t(), list(integer()), Codec.t()) :: iodata()

  def encode_array([], _dimensions, _codec) do
    @empty_list_iodata
  end

  def encode_array(instance, dimensions, codec) when is_list(instance) do
    if Keyword.keyword?(instance) do
      raise Error.invalid_argument_error(
              "unable to encode keyword list #{inspect(instance)} as array"
            )
    end

    ndims = length(dimensions)
    calculated_dimensions = get_dimensions_for_list(ndims, instance)

    elements = encode_data_into_array_elements(instance, codec)

    [
      Datatypes.Int32.encode(ndims),
      Datatypes.Int32.encode(@reserved0),
      Datatypes.Int32.encode(@reserved1),
      Types.Dimension.encode(calculated_dimensions, raw: true),
      Types.ArrayElement.encode(elements, raw: true)
    ]
  end

  @spec decode_array(bitstring(), list(integer()), Codec.t()) :: t()

  def decode_array(<<0::int32, _reserved0::int32, _reserved1::int32>>, _dimensions, _codec) do
    []
  end

  def decode_array(
        <<ndims::int32, _reserved0::int32, _reserved1::int32, rest::binary>>,
        expected_dimensions,
        codec
      ) do
    {parsed_dimensions, rest} = Types.Dimension.decode(ndims, rest)

    if length(parsed_dimensions) != length(expected_dimensions) do
      raise Error.invalid_argument_error(
              "unable to decode binary data as array: parsed dimensions count don't match expected dimensions count"
            )
    end

    elements_count = count_elements_in_array(parsed_dimensions)
    {raw_elements, <<>>} = Types.ArrayElement.decode(elements_count, rest)

    decode_array_elements_into_list(raw_elements, parsed_dimensions, codec)
  end

  @spec encode_data_into_array_elements(list(), Codec.t()) :: iodata()
  defp encode_data_into_array_elements(list, codec) do
    Enum.map(list, fn element ->
      encoded_data = Codec.encode(codec, element)
      array_element(data: encoded_data)
    end)
  end

  @spec decode_array_elements_into_list(
          list(Types.ArrayElement.t()),
          list(Types.Dimension.t()),
          Codec.t()
        ) :: t()
  defp decode_array_elements_into_list(elements, dimensions, codec) do
    elements
    |> Enum.into([], fn array_element(data: data) ->
      Codec.decode(codec, data)
    end)
    |> transform_in_dimensions(dimensions)
  end

  @spec get_dimensions_for_list(non_neg_integer(), list()) :: list(Types.Dimension.t())

  defp get_dimensions_for_list(1, list) do
    get_dimensions_for_list(0, [], [dimension(upper: length(list))])
  end

  defp get_dimensions_for_list(ndims, list) do
    get_dimensions_for_list(ndims, list, [])
  end

  @spec get_dimensions_for_list(
          non_neg_integer(),
          list(),
          list(Types.Dimension.t())
        ) :: list(Types.Dimension.t())

  defp get_dimensions_for_list(0, [], dimensions) do
    dimensions
  end

  defp get_dimensions_for_list(ndims, [list | rest], dimensions) when is_list(list) do
    get_dimensions_for_list(ndims - 1, rest, [dimension(upper: length(list)) | dimensions])
  end

  @spec count_elements_in_array(list(Types.Dimension.t())) :: integer()
  defp count_elements_in_array(dimensions) do
    Enum.reduce(dimensions, 0, fn dimension(upper: upper, lower: lower), acc ->
      acc + upper - lower + 1
    end)
  end

  @spec transform_in_dimensions(list(), list(Types.Dimension.t())) :: t()

  defp transform_in_dimensions(list, [dimension()]) do
    list
  end

  defp transform_in_dimensions(list, dimensions) do
    {list, []} =
      Enum.reduce(dimensions, {[], list}, fn dimension(upper: upper), {md_list, elements} ->
        {new_dim_list, rest} = Enum.split(elements, upper)
        {[new_dim_list | md_list], rest}
      end)

    Enum.reverse(list)
  end
end
