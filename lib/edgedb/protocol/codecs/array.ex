defmodule EdgeDB.Protocol.Codecs.Array do
  use EdgeDB.Protocol.Codec

  import EdgeDB.Protocol.Types.Dimension
  import EdgeDB.Protocol.Types.ArrayElement

  alias EdgeDB.Protocol.{Types, DataTypes}

  @reserved0 0
  @reserved1 0

  defcodec(type: list())

  def new(type_id, dimensions, codec) do
    encoder =
      create_encoder(fn
        [] ->
          [
            DataTypes.Int32.encode(0),
            DataTypes.Int32.encode(@reserved0),
            DataTypes.Int32.encode(@reserved1)
          ]

        list when is_list(list) ->
          if Keyword.keyword?(list) do
            raise EdgeDB.Protocol.Errors.InvalidArgumentError,
                  "unable to encode keyword list as array"
          end

          ndims = length(dimensions)
          dimensions = get_dimensions_for_list(ndims, list)

          elements =
            Enum.map(list, fn element ->
              encoded_data = codec.encoder.(element)
              array_element(data: encoded_data)
            end)

          [
            DataTypes.Int32.encode(ndims),
            DataTypes.Int32.encode(@reserved0),
            DataTypes.Int32.encode(@reserved1),
            Types.Dimension.encode(dimensions, :raw),
            Types.ArrayElement.encode(elements, :raw)
          ]
      end)

    decoder =
      create_decoder(fn
        <<0::int32, _reserved0::int32, _reserved1::int32>> ->
          []

        <<ndims::int32, _reserved0::int32, _reserved1::int32, rest::binary>> ->
          {dimensions, rest} = Types.Dimension.decode(ndims, rest)

          elements_count =
            Enum.reduce(dimensions, 0, fn dimension(upper: upper, lower: lower), acc ->
              acc + upper - lower + 1
            end)

          {raw_elements, <<>>} = Types.ArrayElement.decode(elements_count, rest)

          Enum.into(raw_elements, [], fn array_element(data: data) ->
            codec.decoder.(data)
          end)
      end)

    %Codec{
      type_id: <<type_id::uuid>>,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end

  defp get_dimensions_for_list(1, list) do
    get_dimensions_for_list(0, [], [dimension(upper: length(list))])
  end

  defp get_dimensions_for_list(ndims, list) do
    get_dimensions_for_list(ndims, list, [])
  end

  defp get_dimensions_for_list(0, [], dimensions) do
    dimensions
  end

  defp get_dimensions_for_list(ndims, [list | rest], dimensions) when is_list(list) do
    get_dimensions_for_list(ndims - 1, rest, [dimension(upper: length(list)) | dimensions])
  end
end
