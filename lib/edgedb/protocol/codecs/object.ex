defmodule EdgeDB.Protocol.Codecs.Object do
  use EdgeDB.Protocol.Codec

  import EdgeDB.Protocol.Types.TupleElement
  import EdgeDB.Protocol.Types.ShapeElement

  alias EdgeDB.Protocol.Types

  defcodec(type: EdgeDB.Object.t())

  def new(type_id, shape_elements, elements_codecs) do
    codecs = Enum.reverse(elements_codecs)

    shape_elements =
      shape_elements
      |> Enum.reverse()
      |> Enum.map(fn shape_element(name: name) = e ->
        if link_property?(e) do
          shape_element(e, name: "@#{name}")
        else
          e
        end
      end)

    encoder =
      create_encoder(fn _term ->
        raise EdgeDB.Protocol.Errors.InvalidArgumentError, "objects can't be encoded"
      end)

    decoder =
      create_decoder(fn <<nelems::int32, elements_data::binary>> ->
        {encoded_elements, <<>>} = Types.TupleElement.decode(nelems, elements_data)

        fields =
          [encoded_elements, shape_elements, codecs]
          |> Enum.zip()
          |> Enum.map(fn
            {tuple_element(data: :empty_set), shape_element(name: name) = se, _codec} ->
              %EdgeDB.Object.Field{
                name: name,
                value: EdgeDB.Set._new(),
                link?: link?(se),
                link_property?: link_property?(se),
                implicit?: implicit?(se)
              }

            {tuple_element(data: data), shape_element(name: name) = se, codec} ->
              decoded_element = codec.decoder.(data)

              %EdgeDB.Object.Field{
                name: name,
                value: decoded_element,
                link?: link?(se),
                link_property?: link_property?(se),
                implicit?: implicit?(se)
              }
          end)

        EdgeDB.Object._from_fields(fields)
      end)

    %Codec{
      type_id: <<type_id::uuid>>,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end
end
