defmodule EdgeDB.Protocol.Codecs.UUID do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-000000000100")
  @name "std::uuid"

  defstruct id: @id,
            name: @name

  @impl EdgeDB.Protocol.BaseScalarCodec
  def new do
    %__MODULE__{}
  end

  @impl EdgeDB.Protocol.BaseScalarCodec
  def id do
    @id
  end

  @impl EdgeDB.Protocol.BaseScalarCodec
  def name do
    @name
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.UUID do
  import EdgeDB.Protocol.Converters

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, uuid, _codec_storage) when is_binary(uuid) do
    <<16::uint32, UUID.string_to_binary!(uuid)::uuid>>
  rescue
    e in ArgumentError ->
      reraise EdgeDB.InvalidArgumentError.new(
                "value can not be encoded as std::uuid: #{e.message}"
              ),
              __STACKTRACE__
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as std::uuid: #{inspect(value)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, <<16::uint32, value::uuid>>, _codec_storage) do
    UUID.binary_to_string!(value)
  end
end
