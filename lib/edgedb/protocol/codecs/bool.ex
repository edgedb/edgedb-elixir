defmodule EdgeDB.Protocol.Codecs.Bool do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-000000000109")
  @name "std::bool"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Bool do
  import EdgeDB.Protocol.Converters

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, true, _codec_storage) do
    <<1::uint32(), 1::uint8()>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, false, _codec_storage) do
    <<1::uint32(), 0::uint8()>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as std::bool: #{inspect(value)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, <<1::uint32(), 1::uint8()>>, _codec_storage) do
    true
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, <<1::uint32(), 0::uint8()>>, _codec_storage) do
    false
  end
end
