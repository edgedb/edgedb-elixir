defmodule EdgeDB.Protocol.Codecs.Duration do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-00000000010E")
  @name "std::duration"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Duration do
  import EdgeDB.Protocol.Converters

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, duration, _codec_storage) when is_integer(duration) do
    <<16::uint32, duration::int64, 0::int32, 0::int32>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.Error.invalid_argument_error(
            "value can not be encoded as std::duration: #{inspect(value)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, <<16::uint32, duration::int64, 0::int32, 0::int32>>, _codec_storage) do
    duration
  end
end
