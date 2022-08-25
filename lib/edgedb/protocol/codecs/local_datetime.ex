defmodule EdgeDB.Protocol.Codecs.LocalDateTime do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-00000000010B")
  @name "cal::local_datetime"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.LocalDateTime do
  alias EdgeDB.Protocol.{
    Codec,
    Codecs
  }

  @dt_codec Codecs.DateTime.new()

  @impl Codec
  def encode(_codec, unix_ts, codec_storage) when is_integer(unix_ts) do
    Codec.encode(@dt_codec, unix_ts, codec_storage)
  end

  @impl Codec
  def encode(_codec, %NaiveDateTime{} = ndt, codec_storage) do
    unix_ts =
      ndt
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix()

    Codec.encode(@dt_codec, unix_ts, codec_storage)
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new("value can not be encoded as cal::local_datetime: #{inspect(value)}")
  end

  @impl Codec
  def decode(_codec, data, codec_storage) do
    @dt_codec
    |> Codec.decode(data, codec_storage)
    |> DateTime.to_naive()
  end
end
