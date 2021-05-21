defmodule EdgeDB.Protocol.TypeDescriptors do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    TypeDescriptors
  }

  require TypeDescriptors.TypeAnnotationDescriptor

  @type_descriptors [
    TypeDescriptors.SetDescriptor,
    TypeDescriptors.ObjectShapeDescriptor,
    TypeDescriptors.BaseScalarTypeDescriptor,
    TypeDescriptors.ScalarTypeDescriptor,
    TypeDescriptors.TupleTypeDescriptor,
    TypeDescriptors.NamedTupleTypeDescriptor,
    TypeDescriptors.ArrayTypeDescriptor,
    TypeDescriptors.EnumerationTypeDescriptor
  ]

  @spec parse_type_description_into_codec(list(Codec.t()), bitstring()) :: Codec.t()

  for descriptor_module <- @type_descriptors, descriptor_module.support_parsing?() do
    def parse_type_description_into_codec(
          codecs,
          <<unquote(descriptor_module.type())::uint8, _rest::binary>> = type_description
        ) do
      unquote(descriptor_module).parse(codecs, type_description)
    end
  end

  @spec consume_description(Codecs.Storage.t(), bitstring()) :: Codec.t()

  for descriptor_module <- @type_descriptors, descriptor_module.support_consuming?() do
    def consume_description(
          storage,
          <<unquote(descriptor_module.type())::uint8, _rest::binary>> = type_description
        ) do
      unquote(descriptor_module).consume(storage, type_description)
    end
  end

  def consume_description(storage, <<0xFF::uint8, _rest::binary>> = type_description) do
    TypeDescriptors.ScalarTypeNameAnnotation.consume(storage, type_description)
  end

  def consume_description(storage, <<type::uint8, _rest::binary>> = type_description)
      when TypeDescriptors.TypeAnnotationDescriptor.supported_type?(type) do
    TypeDescriptors.TypeAnnotationDescriptor.consume(storage, type_description)
  end
end
