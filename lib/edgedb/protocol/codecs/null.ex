defmodule EdgeDB.Protocol.Codecs.Null do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-000000000000")

  defstruct id: @id

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
    "null"
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Null do
  import EdgeDB.Protocol.Converters

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, _value, _codec_storage) do
    <<0::uint32>>
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, _data, _codec_storage) do
    raise EdgeDB.Error.internal_client_error("binary data can not be decoded as null")
  end
end
