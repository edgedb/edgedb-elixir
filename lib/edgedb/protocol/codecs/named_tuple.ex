defmodule EdgeDB.Protocol.Codecs.NamedTuple do
  use EdgeDB.Protocol.Codec

  import EdgeDB.Protocol.Types.{
    TupleElement,
    NamedTupleDescriptorElement
  }

  alias EdgeDB.Protocol.{
    DataTypes,
    Types
  }

  defcodec(type: EdgeDB.NamedTuple.t())

  @spec new(DataTypes.UUID.t(), list(Types.NamedTupleDescriptorElement.t()), list(Codec.t())) ::
          Codec.t()
  def new(type_id, elements, codecs) do
    encoder =
      create_encoder(fn instance when is_map(instance) or is_list(instance) ->
        if is_list(instance) and not Keyword.keyword?(instance) do
          raise EdgeDB.Protocol.Errors.InvalidArgumentError,
                "named tuples encoding is supported only for maps, and keyword lists"
        end

        instance =
          Enum.into(instance, %{}, fn
            {key, value} when is_atom(key) ->
              {to_string(key), value}

            {key, value} when is_binary(key) ->
              {key, value}
          end)

        encoded_elements =
          elements
          |> Enum.zip(codecs)
          |> Enum.map(fn {named_tuple_descriptor_element(name: name), codec} ->
            value = instance[name]
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

        [encoded_elements, elements, codecs]
        |> Enum.zip()
        |> Enum.into(%{}, fn {tuple_element(data: data),
                             named_tuple_descriptor_element(name: name), codec} ->
          {name, codec.decoder.(data)}
        end)
        |> EdgeDB.NamedTuple.new()
      end)

    %Codec{
      type_id: <<type_id::uuid>>,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end
end
