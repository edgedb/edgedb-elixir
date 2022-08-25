defmodule EdgeDB.Protocol.Codecs.Enum do
  @moduledoc false

  alias EdgeDB.Protocol.Codec

  defstruct [
    :id,
    :name,
    :members
  ]

  @spec new(Codec.t(), String.t() | nil, list(String.t())) :: Codec.t()
  def new(id, name, members) do
    %__MODULE__{id: id, name: name, members: members}
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
    cond do
      is_binary(value) and value in members ->
        Codec.encode(@str_codec, value, codec_storage)

      is_atom(value) and to_string(value) in members ->
        Codec.encode(@str_codec, to_string(value), codec_storage)

      true ->
        raise EdgeDB.InvalidArgumentError.new("value can not be encoded as enum: not enum member: #{inspect(value)}")
    end
  end

  @impl Codec
  def decode(_codec, data, codec_storage) do
    Codec.decode(@str_codec, data, codec_storage)
  end
end
