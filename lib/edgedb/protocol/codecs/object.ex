defmodule EdgeDB.Protocol.Codecs.Object do
  use EdgeDB.Protocol.Codec

  import EdgeDB.Protocol.Types.{
    TupleElement,
    ShapeElement
  }

  alias EdgeDB.Protocol.{
    Datatypes,
    Errors,
    Types
  }

  defcodec(type: EdgeDB.Object.t())

  @spec new(Datatypes.UUID.t(), list(Types.ShapeElement.t()), list(Codec.t())) :: Codec.t()
  def new(type_id, shape_elements, codecs) do
    shape_elements = transform_shape_elements(shape_elements)

    encoder = create_encoder(&encode_object(&1))
    decoder = create_decoder(&decode_object(&1, shape_elements, codecs))

    %Codec{
      type_id: type_id,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end

  @spec encode_object(EdgeDB.Object.t()) :: no_return()
  def encode_object(%EdgeDB.Object{}) do
    raise Errors.InvalidArgumentError, "objects can't be encoded"
  end

  @spec decode_object(
          bitstring(),
          list(Types.ShapeElement.t()),
          list(Codec.t())
        ) :: EdgeDB.Object.t()
  def decode_object(
        <<nelems::int32, elements_data::binary>>,
        object_shape_elements,
        codecs
      ) do
    {encoded_elements, <<>>} = Types.TupleElement.decode(nelems, elements_data)

    fields = decode_fields(encoded_elements, object_shape_elements, codecs)

    EdgeDB.Object.from_fields(fields)
  end

  @spec decode_fields(
          list(Types.TupleElement.t()),
          list(Types.ShapeElement.t()),
          list(Codec.t())
        ) :: list(EdgeDB.Object.Field.t())
  defp decode_fields(object_fields, shape_elements, codecs) do
    [object_fields, shape_elements, codecs]
    |> Enum.zip()
    |> Enum.map(fn {field_data, shape_element, codec} ->
      decode_field_data(field_data, shape_element, codec)
    end)
  end

  @spec decode_field_data(
          Types.TupleElement.t(),
          Types.ShapeElement.t(),
          Codec.t()
        ) :: EdgeDB.Object.Field.t()

  defp decode_field_data(tuple_element(data: :empty_set), shape_element(name: name) = se, _codec) do
    %EdgeDB.Object.Field{
      name: name,
      value: EdgeDB.Set.new(),
      link?: link?(se),
      link_property?: link_property?(se),
      implicit?: implicit?(se)
    }
  end

  defp decode_field_data(tuple_element(data: data), shape_element(name: name) = se, codec) do
    decoded_element = Codec.decode(codec, data)

    %EdgeDB.Object.Field{
      name: name,
      value: decoded_element,
      link?: link?(se),
      link_property?: link_property?(se),
      implicit?: implicit?(se)
    }
  end

  @spec transform_shape_elements(list(Types.ShapeElement.t())) :: list(Types.ShapeElement.t())
  defp transform_shape_elements(shape_elements) do
    Enum.map(shape_elements, fn shape_element(name: name) = e ->
      if link_property?(e) do
        shape_element(e, name: "@#{name}")
      else
        e
      end
    end)
  end
end
