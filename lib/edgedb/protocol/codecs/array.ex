defmodule EdgeDB.Protocol.Codecs.Array do
  use EdgeDB.Protocol.Codec

  import EdgeDB.Protocol.Types.{
    ArrayElement,
    Dimension
  }

  alias EdgeDB.Protocol.{
    DataTypes,
    Errors,
    Types
  }

  @reserved0 0
  @reserved1 0
  @empty_list_iodata [
    DataTypes.Int32.encode(0),
    DataTypes.Int32.encode(@reserved0),
    DataTypes.Int32.encode(@reserved1)
  ]

  defcodec(type: list())

  @spec new(DataTypes.UUID.t(), list(integer()), Codec.t()) :: Codec.t()
  def new(type_id, dimensions, codec) do
    encoder =
      create_encoder(fn
        [] ->
          @empty_list_iodata

        list when is_list(list) ->
          if Keyword.keyword?(list) do
            raise Errors.InvalidArgumentError, "unable to encode keyword list as array"
          end

          ndims = length(dimensions)
          calculated_dimensions = get_dimensions_for_list(ndims, list)

          elements = encode_array_elements(list, codec)

          [
            DataTypes.Int32.encode(ndims),
            DataTypes.Int32.encode(@reserved0),
            DataTypes.Int32.encode(@reserved1),
            Types.Dimension.encode(calculated_dimensions, :raw),
            Types.ArrayElement.encode(elements, :raw)
          ]
      end)

    decoder =
      create_decoder(fn
        <<0::int32, _reserved0::int32, _reserved1::int32>> ->
          []

        <<ndims::int32, _reserved0::int32, _reserved1::int32, rest::binary>> ->
          {parsed_dimensions, rest} = Types.Dimension.decode(ndims, rest)

          elements_count = count_elements_in_array(parsed_dimensions)
          {raw_elements, <<>>} = Types.ArrayElement.decode(elements_count, rest)

          raw_elements
          |> Enum.into([], fn array_element(data: data) ->
            codec.decoder.(data)
          end)
          |> transform_in_dimensions(parsed_dimensions)
      end)

    %Codec{
      type_id: <<type_id::uuid>>,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end

  @spec get_dimensions_for_list(non_neg_integer(), list(Types.Dimension.t())) ::
          list(Types.Dimension.t())

  defp get_dimensions_for_list(1, list) do
    get_dimensions_for_list(0, [], [dimension(upper: length(list))])
  end

  defp get_dimensions_for_list(ndims, list) do
    get_dimensions_for_list(ndims, list, [])
  end

  @spec get_dimensions_for_list(non_neg_integer(), list(), list(Types.Dimension.t())) ::
          list(Types.Dimension.t())

  defp get_dimensions_for_list(0, [], dimensions) do
    dimensions
  end

  defp get_dimensions_for_list(ndims, [list | rest], dimensions) when is_list(list) do
    get_dimensions_for_list(ndims - 1, rest, [dimension(upper: length(list)) | dimensions])
  end

  @spec encode_array_elements(list(), Codec.t()) :: list(Types.ArrayElement.t())
  defp encode_array_elements(list, %Codec{encoder: encoder}) do
    Enum.map(list, fn element ->
      encoded_data = encoder.(element)
      array_element(data: encoded_data)
    end)
  end

  @spec count_elements_in_array(list(Types.Dimension.t())) :: non_neg_integer()
  defp count_elements_in_array(dimensions) do
    Enum.reduce(dimensions, 0, fn dimension(upper: upper, lower: lower), acc ->
      acc + upper - lower + 1
    end)
  end

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
