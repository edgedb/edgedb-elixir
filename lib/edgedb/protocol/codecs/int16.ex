defmodule EdgeDB.Protocol.Codecs.Int16 do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-000000000103")
  @name "std::int16"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Int16 do
  import EdgeDB.Protocol.Converters

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, number, _codec_storage)
      when is_integer(number) and number in -0x8000..0x7FFF do
    <<2::uint32(), number::int16()>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new("value can not be encoded as std::int16: #{inspect(value)}")
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, <<2::uint32(), number::int16()>>, _codec_storage) do
    number
  end
end
