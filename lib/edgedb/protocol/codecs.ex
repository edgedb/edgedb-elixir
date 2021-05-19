defmodule EdgeDB.Protocol.Codecs do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{Codecs, TypeDescriptors}

  def from_type_description(storage, type_description) do
    create_codec_from_type_description(storage, type_description)
  end

  def create_codec_from_type_description(storage, data) do
    create_codec_from_type_description(storage, data, [])
  end

  def create_codec_from_type_description(_storage, <<>>, [codec | _codecs]) do
    codec
  end

  def create_codec_from_type_description(
        storage,
        <<_type::uint8, type_id::uuid, _rest::binary>> = type_description,
        codecs
      ) do
    {codec, data} =
      case Codecs.Storage.get(storage, type_id) do
        nil ->
          {codec, rest} =
            TypeDescriptors.parse_type_description_into_codec(codecs, type_description)

          Codecs.Storage.register(storage, codec)

          {codec, rest}

        codec ->
          rest = TypeDescriptors.consume_description(storage, type_description)

          {codec, rest}
      end

    create_codec_from_type_description(storage, data, [codec | codecs])
  end
end
