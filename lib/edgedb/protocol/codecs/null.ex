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

  alias EdgeDB.Protocol.Codec.EdgeDB.Protocol.Codecs.Object

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, [], _codec_storage) do
    <<0::uint32>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, arguments, _codec_storage) when map_size(arguments) == 0 do
    <<0::uint32>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, arguments, _codec_storage) when is_list(arguments) or is_map(arguments) do
    arguments
    |> Object.transform_arguments()
    |> Object.raise_wrong_arguments_error!([])
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    EdgeDB.InvalidArgumentError.new("value can not be encoded as null: #{inspect(value)}")
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, _data, _codec_storage) do
    raise EdgeDB.InternalClientError.new("binary data can not be decoded as null")
  end
end
