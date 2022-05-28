defmodule EdgeDB.Protocol.Codecs.ConfigMemory do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-000000000130")
  @name "cfg::memory"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.ConfigMemory do
  import EdgeDB.Protocol.Converters

  @impl EdgeDB.Protocol.Codec
  def encode(codec, %EdgeDB.ConfigMemory{} = m, codec_storage) do
    encode(codec, m.bytes, codec_storage)
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, bytes, _codec_storage)
      when is_integer(bytes) and bytes in -0x8000000000000000..0x7FFFFFFFFFFFFFFF do
    <<8::uint32, bytes::int64>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as cfg::memory: #{inspect(value)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, <<8::uint32, bytes::int64>>, _codec_storage) do
    %EdgeDB.ConfigMemory{bytes: bytes}
  end
end
