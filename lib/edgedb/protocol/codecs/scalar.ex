defmodule EdgeDB.Protocol.Codecs.Scalar do
  @moduledoc false

  alias EdgeDB.Protocol.Codec

  defstruct [
    :id,
    :name,
    :codec
  ]

  @spec new(Codec.id(), String.t() | nil, Codec.id()) :: Codec.t()
  def new(id, name, codec) do
    %__MODULE__{id: id, name: name, codec: codec}
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Scalar do
  alias EdgeDB.Protocol.{
    Codec,
    CodecStorage
  }

  @impl Codec
  def encode(%{codec: codec}, value, codec_storage) do
    codec = CodecStorage.get(codec_storage, codec)
    Codec.encode(codec, value, codec_storage)
  end

  @impl Codec
  def decode(%{codec: codec}, data, codec_storage) do
    codec = CodecStorage.get(codec_storage, codec)
    Codec.decode(codec, data, codec_storage)
  end
end
