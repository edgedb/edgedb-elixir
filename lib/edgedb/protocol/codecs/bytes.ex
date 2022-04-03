defmodule EdgeDB.Protocol.Codecs.Bytes do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-000000000102")
  @name "std::bytes"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Bytes do
  import EdgeDB.Protocol.Converters

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, bytes, _codec_storage) when is_binary(bytes) do
    [<<byte_size(bytes)::uint32>>, bytes]
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.Error.invalid_argument_error(
            "value can not be encoded as std::bytes: #{inspect(value)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, <<bytes_size::uint32, bytes::binary(bytes_size)>>, _codec_storage) do
    :binary.copy(bytes)
  end
end
