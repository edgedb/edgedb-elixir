defmodule EdgeDB.Protocol.Codecs.LocalDate do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-00000000010C")
  @name "cal::local_date"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.LocalDate do
  import EdgeDB.Protocol.Converters

  @base_date elem(Date.new(2000, 1, 1), 1)

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, %Date{} = d, _codec_storage) do
    days =
      @base_date
      |> Date.diff(d)
      |> abs()

    <<4::uint32(), days::int32()>>
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as cal::local_date: #{inspect(value)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def decode(_codec, <<4::uint32(), days::int32()>>, _codec_storage) do
    Date.add(@base_date, days)
  end
end
