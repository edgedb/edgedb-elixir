defmodule Tests.Support.Codecs.ShortStr do
  @behaviour EdgeDB.Protocol.CustomCodec

  defstruct []

  @impl EdgeDB.Protocol.CustomCodec
  def new do
    %__MODULE__{}
  end

  @impl EdgeDB.Protocol.CustomCodec
  def name do
    "default::short_str"
  end
end

defimpl EdgeDB.Protocol.Codec, for: Tests.Support.Codecs.ShortStr do
  alias EdgeDB.Protocol.{Codec, Codecs}

  @str_codec Codecs.Str.new()

  @impl Codec
  def encode(_codec, value, codec_storage) when is_binary(value) do
    if String.length(value) <= 5 do
      Codec.encode(@str_codec, value, codec_storage)
    else
      raise EdgeDB.InvalidArgumentError.new("string is too long")
    end
  end

  @impl Codec
  def decode(_codec, data, codec_storage) do
    Codec.decode(@str_codec, data, codec_storage)
  end
end
