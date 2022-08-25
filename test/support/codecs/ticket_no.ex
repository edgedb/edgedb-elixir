defmodule Tests.Support.Codecs.TicketNo do
  @behaviour EdgeDB.Protocol.CustomCodec

  defstruct []

  @impl EdgeDB.Protocol.CustomCodec
  def new do
    %__MODULE__{}
  end

  @impl EdgeDB.Protocol.CustomCodec
  def name do
    "v1::TicketNo"
  end
end

defimpl EdgeDB.Protocol.Codec, for: Tests.Support.Codecs.TicketNo do
  alias Tests.Support.TicketNo
  alias EdgeDB.Protocol.{Codec, Codecs}

  @int64_codec Codecs.Int64.new()

  @impl Codec
  def encode(_codec, %TicketNo{number: number}, codec_storage) do
    Codec.encode(@int64_codec, number, codec_storage)
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new("value can not be encoded as v1::TicketNo: #{inspect(value)}")
  end

  @impl Codec
  def decode(_codec, data, codec_storage) do
    number = Codec.decode(@int64_codec, data, codec_storage)
    %TicketNo{number: number}
  end
end
