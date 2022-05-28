defmodule EdgeDB.Protocol.Codecs.Enum do
  @moduledoc false

  alias EdgeDB.Protocol.Codec

  defstruct [:id, :members]

  @spec new(Codec.t(), list(String.t())) :: Codec.t()
  def new(id, members) do
    %__MODULE__{id: id, members: members}
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Enum do
  alias EdgeDB.Protocol.{
    Codec,
    Codecs
  }

  @str_codec Codecs.Str.new()

  @impl Codec
  def encode(%{members: members}, value, codec_storage) do
    if value in members do
      Codec.encode(@str_codec, value, codec_storage)
    else
      raise EdgeDB.InvalidArgumentError.new(
              "value can not be encoded as enum: not enum member: #{inspect(value)}"
            )
    end
  end

  @impl Codec
  def decode(_codec, data, codec_storage) do
    Codec.decode(@str_codec, data, codec_storage)
  end
end
