defmodule EdgeDB.Protocol.Codecs.Decimal do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-000000000108")
  @name "std::decimal"

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

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.Decimal do
  import EdgeDB.Protocol.Converters

  @base 10_000

  @impl EdgeDB.Protocol.Codec
  def encode(codec, number, codec_storage) when is_integer(number) do
    encode(codec, Decimal.new(number), codec_storage)
  end

  @impl EdgeDB.Protocol.Codec
  def encode(codec, number, codec_storage) when is_float(number) do
    encode(codec, Decimal.from_float(number), codec_storage)
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, %Decimal{coef: coef} = number, _codec_storage) when not is_number(coef) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as std::decimal: coef #{inspect(coef)} is not a number: #{inspect(number)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, %Decimal{} = number, _codec_storage) do
    sign =
      case number.sign do
        1 ->
          0x0000

        -1 ->
          0x4000
      end

    scale = -number.exp

    scale_4digits =
      if scale < 0 do
        scale / 4
      else
        scale / 4 + 1
      end

    scale_4digits = trunc(scale_4digits)

    padding = scale_4digits * 4 - scale

    number =
      if padding > 0 do
        number.coef * :math.pow(10, padding)
      else
        number.coef
      end

    number = trunc(number)

    digits = Integer.digits(number, @base)
    ndigits = length(digits)

    dscale = max(0, scale)
    weight = ndigits - scale_4digits - 1

    data =
      for digit <- digits do
        <<digit::uint16()>>
      end

    data = [<<ndigits::uint16(), weight::int16(), sign::uint16(), dscale::uint16()>> | data]
    [<<IO.iodata_length(data)::uint32()>> | data]
  end

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.InvalidArgumentError.new(
            "value can not be encoded as std::decimal: #{inspect(value)}"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def decode(
        _codec,
        <<length::uint32(), data::binary(length)>>,
        _codec_storage
      ) do
    <<ndigits::uint16(), weight::int16(), sign::uint16(), dscale::uint16(), rest::binary>> = data
    digits = decode_digit_list(rest, ndigits, [])
    number = Integer.undigits(digits, @base)

    decimals_stored = 4 * max(0, ndigits - weight - 1)
    {padding, number} = get_decimal_padding(number, dscale, decimals_stored)
    {scale, number} = get_decimal_scale(number, dscale, weight, ndigits, padding, decimals_stored)

    sign =
      case sign do
        0x0000 ->
          1

        0x4000 ->
          -1
      end

    Decimal.new(sign, number, -scale)
  end

  defp decode_digit_list(<<>>, 0, acc) do
    Enum.reverse(acc)
  end

  defp decode_digit_list(<<digit::uint16(), rest::binary>>, count, acc) do
    decode_digit_list(rest, count - 1, [digit | acc])
  end

  defp get_decimal_padding(number, _scale, decimals_stored) when decimals_stored <= 0 do
    {0, number}
  end

  defp get_decimal_padding(number, scale, decimals_stored) do
    padding = decimals_stored - scale

    number =
      cond do
        padding > 0 ->
          number / :math.pow(10, padding)

        padding < 0 ->
          number * :math.pow(10, -padding)

        true ->
          number
      end

    {padding, trunc(number)}
  end

  defp get_decimal_scale(number, 0, weight, digits_count, padding, _decimals_stored) do
    {-(weight + 1 - digits_count) * 4 - padding, number}
  end

  defp get_decimal_scale(number, scale, weight, digits_count, _padding, decimals_stored) do
    power = (weight + 1 - digits_count) * 4 + scale

    number =
      if decimals_stored == 0 and power > 0 do
        number * :math.pow(10, power)
      else
        number
      end

    {scale, trunc(number)}
  end
end
