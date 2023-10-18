defmodule EdgeDB.Protocol.Codecs.Range do
  @moduledoc false

  alias EdgeDB.Protocol.Codec

  defstruct [
    :id,
    :name,
    :codec
  ]

  @spec new(Codec.id(), String.t() | nil, Codec.t()) :: Codec.t()
  def new(id, name, codec) do
    %__MODULE__{id: id, name: name, codec: codec}
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Range do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    CodecStorage,
    Codec
  }

  @empty 0x01
  @lb_inc 0x02
  @ub_inc 0x04
  @lb_inf 0x08
  @ub_inf 0x10

  @impl Codec
  def encode(%{codec: codec}, %EdgeDB.Range{} = range, codec_storage) do
    codec = CodecStorage.get(codec_storage, codec)
    flags = encode_range_flags(range)

    data =
      Enum.reject(
        [
          <<flags::uint8()>>,
          range.lower && Codec.encode(codec, range.lower, codec_storage),
          range.upper && Codec.encode(codec, range.upper, codec_storage)
        ],
        &is_nil/1
      )

    [<<IO.iodata_length(data)::uint32()>> | data]
  end

  @impl Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new("value can not be encoded as range: #{inspect(value)}")
  end

  @impl Codec
  def decode(
        %{codec: codec},
        <<range_length::uint32(), range_data::binary(range_length)>>,
        codec_storage
      ) do
    codec = CodecStorage.get(codec_storage, codec)

    <<flags::uint8(), boundaries_data::binary>> = range_data

    empty? = Bitwise.band(flags, @empty) != 0
    inc_lower? = Bitwise.band(flags, @lb_inc) != 0
    inc_upper? = Bitwise.band(flags, @ub_inc) != 0
    contains_lower? = Bitwise.band(flags, Bitwise.bor(@empty, @lb_inf)) == 0
    contains_upper? = Bitwise.band(flags, Bitwise.bor(@empty, @ub_inf)) == 0

    {lower, upper_data} =
      if contains_lower? do
        case boundaries_data do
          <<-1::int32(), upper_data::binary>> ->
            {nil, upper_data}

          <<lower_length::int32(), lower_data::binary(lower_length), upper_data::binary>> ->
            lower =
              Codec.decode(codec, <<lower_length::uint32(), lower_data::binary>>, codec_storage)

            {lower, upper_data}
        end
      else
        {nil, boundaries_data}
      end

    upper =
      if contains_upper? do
        case upper_data do
          <<-1::int32()>> ->
            nil

          <<upper_length::uint32(), upper_data::binary(upper_length)>> ->
            Codec.decode(codec, <<upper_length::uint32(), upper_data::binary>>, codec_storage)
        end
      else
        <<>> = boundaries_data
        nil
      end

    %EdgeDB.Range{
      lower: lower,
      upper: upper,
      inc_lower: inc_lower?,
      inc_upper: inc_upper?,
      is_empty: empty?
    }
  end

  defp encode_range_flags(%EdgeDB.Range{is_empty: true}) do
    @empty
  end

  defp encode_range_flags(%EdgeDB.Range{} = range) do
    flags = 0x0

    flags =
      cond do
        is_nil(range.lower) ->
          Bitwise.bor(flags, @lb_inf)

        range.inc_lower ->
          Bitwise.bor(flags, @lb_inc)

        true ->
          flags
      end

    cond do
      is_nil(range.upper) ->
        Bitwise.bor(flags, @ub_inf)

      range.inc_upper ->
        Bitwise.bor(flags, @ub_inc)

      true ->
        flags
    end
  end
end
