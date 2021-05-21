defmodule EdgeDB.Protocol.Codecs.Tuple do
  use EdgeDB.Protocol.Codec

  import EdgeDB.Protocol.Types.TupleElement

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defcodec(type: tuple())

  @spec new(DataTypes.UUID.t(), list(Codec.t())) :: Codec.t()
  def new(type_id, codecs) do
    encoder =
      create_encoder(fn
        instance when is_list(instance) or is_tuple(instance) ->
          instance =
            if is_tuple(instance) do
              Tuple.to_list(instance)
            else
              instance
            end

          encoded_elements =
            instance
            |> Enum.zip(codecs)
            |> Enum.map(fn {value, codec} ->
              codec.encoder.(value)
            end)
            |> Enum.map(fn element_data ->
              tuple_element(data: element_data)
            end)
            |> Types.TupleElement.encode(:raw)

          [DataTypes.Int32.encode(length(encoded_elements)), encoded_elements]
      end)

    decoder =
      create_decoder(fn <<nelems::int32, data::binary>> ->
        {encoded_elements, <<>>} = Types.TupleElement.decode(nelems, data)

        encoded_elements
        |> Enum.zip(codecs)
        |> Enum.into([], fn {tuple_element(data: data), codec} ->
          codec.decoder.(data)
        end)
        |> List.to_tuple()
      end)

    %Codec{
      type_id: <<type_id::uuid>>,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end
end
