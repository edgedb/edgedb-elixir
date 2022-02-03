defmodule EdgeDB.Protocol.Codecs.Builtin.Object do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  @empty_set %EdgeDB.Set{__items__: MapSet.new()}

  defcodec(type: EdgeDB.Object.t() | list() | Keyword.t())

  @spec new(Datatypes.UUID.t(), list(Types.ShapeElement.t()), list(Codec.t())) :: Codec.t()
  def new(type_id, shape_elements, codecs) do
    shape_elements = transform_shape_elements(shape_elements)

    encoder = create_encoder(&encode_object(&1, shape_elements, codecs))
    decoder = create_decoder(&decode_object(&1, shape_elements, codecs))

    %Codec{
      type_id: type_id,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end

  @spec encode_object(
          EdgeDB.Object.t(),
          list(Types.ShapeElement.t()),
          list(Codec.t())
        ) :: no_return()
  def encode_object(%EdgeDB.Object{}, _elements, _codecs) do
    raise EdgeDB.Error.invalid_argument_error("objects can't be encoded")
  end

  @spec encode_object(
          list() | Keyword.t(),
          list(Types.ShapeElement.t()),
          list(Codec.t())
        ) :: iodata()
  def encode_object(query_arguments, elements, codecs) when is_list(query_arguments) do
    arguments =
      if Keyword.keyword?(query_arguments) do
        transform_into_string_map(query_arguments)
      else
        transform_into_indexed_string_map(query_arguments)
      end

    verify_all_arguments_passed!(arguments, elements)
    encoded_arguments = encode_arguments(arguments, elements, codecs)

    [Datatypes.Int32.encode(length(encoded_arguments)), encoded_arguments]
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

    encoded_elements
    |> decode_fields(object_shape_elements, codecs)
    |> create_object_from_fields()
  end

  defp encode_arguments(arguments, elements_descriptors, codecs) do
    elements_descriptors
    |> Enum.zip(codecs)
    |> Enum.map(fn {%Types.ShapeElement{name: name, cardinality: cardinality}, codec} ->
      value = arguments[name]

      if is_nil(value) and (cardinality == :one or cardinality == :at_least_one) do
        raise EdgeDB.Error.invalid_argument_error(
                "argument #{name} is required, but received nil"
              )
      end

      {value, codec}
    end)
    |> Enum.map(fn
      {nil, _codec} ->
        %Types.TupleElement{data: :empty_set}

      {value, codec} ->
        element_data = Codec.encode(codec, value)
        %Types.TupleElement{data: element_data}
    end)
    |> Types.TupleElement.encode(raw: true)
  end

  defp decode_fields(object_fields, shape_elements, codecs) do
    [object_fields, shape_elements, codecs]
    |> Enum.zip()
    |> Enum.map(fn {field_data, shape_element, codec} ->
      decode_field_data(field_data, shape_element, codec)
    end)
  end

  defp decode_field_data(
         %Types.TupleElement{data: :empty_set},
         %Types.ShapeElement{name: name} = se,
         _codec
       ) do
    %EdgeDB.Object.Field{
      name: name,
      value: @empty_set,
      is_link: Types.ShapeElement.link?(se),
      is_link_property: Types.ShapeElement.link_property?(se),
      is_implicit: Types.ShapeElement.implicit?(se)
    }
  end

  defp decode_field_data(
         %Types.TupleElement{data: data},
         %Types.ShapeElement{name: name} = se,
         codec
       ) do
    decoded_element = Codec.decode(codec, data)

    %EdgeDB.Object.Field{
      name: name,
      value: decoded_element,
      is_link: Types.ShapeElement.link?(se),
      is_link_property: Types.ShapeElement.link_property?(se),
      is_implicit: Types.ShapeElement.implicit?(se)
    }
  end

  defp verify_all_arguments_passed!(arguments, elements) do
    passed_keys =
      arguments
      |> Map.keys()
      |> MapSet.new()

    required_keys =
      Enum.into(elements, MapSet.new(), fn %Types.ShapeElement{name: name} ->
        name
      end)

    missed_keys = MapSet.difference(required_keys, passed_keys)
    extra_keys = MapSet.difference(passed_keys, required_keys)

    if MapSet.size(missed_keys) != 0 or MapSet.size(extra_keys) != 0 do
      err =
        required_keys
        |> make_wrong_arguments_error_message(passed_keys, missed_keys, extra_keys)
        |> EdgeDB.Error.query_argument_error()

      raise err
    end

    :ok
  end

  defp transform_shape_elements(shape_elements) do
    Enum.map(shape_elements, fn %Types.ShapeElement{name: name} = e ->
      if Types.ShapeElement.link_property?(e) do
        %Types.ShapeElement{e | name: "@#{name}"}
      else
        e
      end
    end)
  end

  defp transform_into_string_map(query_arguments) do
    Enum.into(query_arguments, %{}, fn
      {key, value} when is_atom(key) ->
        {to_string(key), value}

      {key, value} when is_binary(key) ->
        {key, value}
    end)
  end

  defp transform_into_indexed_string_map(query_arguments) do
    query_arguments
    |> Enum.with_index()
    |> Enum.into(%{}, fn {value, index} ->
      {to_string(index), value}
    end)
  end

  defp make_wrong_arguments_error_message(required_args, passed_args, missed_args, extra_args) do
    error_message = "exptected #{MapSet.to_list(required_args)} keyword arguments"
    error_message = "#{error_message}, got #{MapSet.to_list(passed_args)}"

    error_message =
      if MapSet.size(missed_args) != 0 do
        "#{error_message}, missed #{MapSet.to_list(missed_args)}"
      else
        error_message
      end

    if MapSet.size(extra_args) != 0 do
      "#{error_message}, missed #{MapSet.to_list(extra_args)}"
    else
      error_message
    end
  end

  defp create_object_from_fields(fields) do
    id =
      case find_field(fields, "id") do
        nil ->
          nil

        field ->
          field.value
      end

    type_id =
      case find_field(fields, "__tid__") do
        nil ->
          nil

        field ->
          field.value
      end

    %EdgeDB.Object{
      id: id,
      __tid__: type_id,
      __fields__: fields
    }
  end

  defp find_field(fields, name_to_find) do
    Enum.find(fields, fn %{name: name} ->
      name == name_to_find
    end)
  end
end
