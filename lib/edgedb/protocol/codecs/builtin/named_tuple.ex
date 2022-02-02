defmodule EdgeDB.Protocol.Codecs.Builtin.NamedTuple do
  @moduledoc false

  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Datatypes,
    Types
  }

  @type named_tuple() :: %EdgeDB.NamedTuple{
          __fields_ordering__: %{integer() => String.t()},
          __items__: %{String.t() => any()}
        }

  defcodec(type: named_tuple())

  @spec new(
          Datatypes.UUID.t(),
          list(Types.NamedTupleDescriptorElement.t()),
          list(Codec.t())
        ) :: Codec.t()
  def new(type_id, named_tuple_elements, codecs) do
    encoder = create_encoder(&encode_named_tuple(&1, named_tuple_elements, codecs))
    decoder = create_decoder(&decode_named_tuple(&1, named_tuple_elements, codecs))

    %Codec{
      type_id: type_id,
      encoder: encoder,
      decoder: decoder,
      module: __MODULE__
    }
  end

  @spec encode_named_tuple(
          map() | Keyword.t(),
          list(Types.NamedTupleDescriptorElement.t()),
          list(Codec.t())
        ) :: iodata()
  def encode_named_tuple(instance, named_tuple_elements, codecs)
      when is_map(instance) or is_list(instance) do
    if is_list(instance) and not Keyword.keyword?(instance) do
      raise EdgeDB.Error.invalid_argument_error(
              "named tuples encoding is supported only for maps, and keyword lists"
            )
    end

    instance = transform_into_string_map(instance)
    verify_all_members_passed!(instance, named_tuple_elements)
    encoded_elements = encode_elements(instance, named_tuple_elements, codecs)

    [Datatypes.Int32.encode(length(encoded_elements)), encoded_elements]
  end

  @spec decode_named_tuple(
          bitstring(),
          list(Types.NamedTupleDescriptorElement.t()),
          list(Codec.t())
        ) :: t()
  def decode_named_tuple(<<nelems::int32, data::binary>>, named_tuple_elements, codecs) do
    {encoded_elements, <<>>} = Types.TupleElement.decode(nelems, data)
    decode_elements(encoded_elements, named_tuple_elements, codecs)
  end

  defp transform_into_string_map(instance) do
    Enum.into(instance, %{}, fn
      {key, value} when is_atom(key) ->
        {to_string(key), value}

      {key, value} when is_binary(key) ->
        {key, value}
    end)
  end

  defp encode_elements(instance, elements_descriptors, codecs) do
    elements_descriptors
    |> Enum.zip(codecs)
    |> Enum.map(fn {%Types.NamedTupleDescriptorElement{name: name}, codec} ->
      {instance[name], codec}
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

  defp decode_elements(tuple_elements, descriptor_elements, codecs) do
    [tuple_elements, descriptor_elements, codecs]
    |> Enum.zip()
    |> Enum.into(%{}, fn {
                           %Types.TupleElement{data: data},
                           %Types.NamedTupleDescriptorElement{name: name},
                           codec
                         } ->
      {name, Codec.decode(codec, data)}
    end)
    |> create_named_tuple(descriptor_elements)
  end

  defp verify_all_members_passed!(instance, elements) do
    passed_keys =
      instance
      |> Map.keys()
      |> MapSet.new()

    required_keys =
      Enum.into(elements, MapSet.new(), fn %Types.NamedTupleDescriptorElement{name: name} ->
        name
      end)

    missed_keys = MapSet.difference(required_keys, passed_keys)
    extra_keys = MapSet.difference(passed_keys, required_keys)

    if MapSet.size(missed_keys) != 0 or MapSet.size(extra_keys) != 0 do
      err =
        required_keys
        |> make_wrong_elements_error_message(passed_keys, missed_keys, extra_keys)
        |> EdgeDB.Error.query_argument_error()

      raise err
    end

    :ok
  end

  defp make_wrong_elements_error_message(required_keys, passed_keys, missed_keys, extra_keys) do
    error_message = "exptected #{MapSet.to_list(required_keys)} keys in named tuple, \
                     got #{MapSet.to_list(passed_keys)}"

    error_message =
      if MapSet.size(missed_keys) != 0 do
        "#{error_message}, missed #{MapSet.to_list(missed_keys)}"
      else
        error_message
      end

    if MapSet.size(extra_keys) != 0 do
      "#{error_message}, missed #{MapSet.to_list(extra_keys)}"
    else
      error_message
    end
  end

  defp create_named_tuple(elements, descriptor_fields) do
    ordering =
      descriptor_fields
      |> Enum.with_index()
      |> Enum.into(%{}, fn {%Types.NamedTupleDescriptorElement{name: name}, index} ->
        {index, name}
      end)

    %EdgeDB.NamedTuple{__items__: elements, __fields_ordering__: ordering}
  end
end
