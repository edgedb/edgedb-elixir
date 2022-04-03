defmodule EdgeDB.Protocol.Codecs.LocalTime do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-00000000010D")
  @name "cal::local_time"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.LocalTime do
  import EdgeDB.Protocol.Converters

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, %Time{} = t, _codec_storage) do
    {seconds, microseconds} = Time.to_seconds_after_midnight(t)
    microseconds = microseconds + System.convert_time_unit(seconds, :second, :microsecond)

    <<8::uint32, microseconds::int64>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.Error.invalid_argument_error(
            "value can not be encoded as cal::local_date: #{inspect(value)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, <<8::uint32, microseconds::int64>>, _codec_storage) do
    microseconds
    |> System.convert_time_unit(:microsecond, :second)
    |> Time.from_seconds_after_midnight()
  end
end
