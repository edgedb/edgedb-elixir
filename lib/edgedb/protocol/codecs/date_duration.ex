defmodule EdgeDB.Protocol.Codecs.DateDuration do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-000000000112")
  @name "cal::date_duration"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.DateDuration do
  import EdgeDB.Protocol.Converters

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, %EdgeDB.DateDuration{} = d, _codec_storage) do
    <<16::uint32(), 0::int64(), d.days::int32(), d.months::int32()>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as cal::date_duration: #{inspect(value)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def decode(
        _codec,
        <<16::uint32(), _reserved::int64(), days::int32(), months::int32()>>,
        _codec_storage
      ) do
    %EdgeDB.DateDuration{
      days: days,
      months: months
    }
  end
end
