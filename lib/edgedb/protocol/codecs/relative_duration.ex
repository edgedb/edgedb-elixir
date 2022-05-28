defmodule EdgeDB.Protocol.Codecs.RelativeDuration do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-000000000111")
  @name "cal::relative_duration"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.RelativeDuration do
  import EdgeDB.Protocol.Converters

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, %EdgeDB.RelativeDuration{} = r, _codec_storage) do
    <<16::uint32, r.microseconds::int64, r.days::int32, r.months::int32>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as cal::relative_duration: #{inspect(value)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def decode(
        _codec,
        <<16::uint32, microseconds::int64, days::int32, months::int32>>,
        _codec_storage
      ) do
    %EdgeDB.RelativeDuration{
      microseconds: microseconds,
      days: days,
      months: months
    }
  end
end
