defmodule EdgeDB.Protocol.Codecs.Decimal do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums,
    Errors
  }

  require Enums.DecimalSign

  @base 10_000

  defbasescalarcodec(
    type_name: "std::decimal",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000108"),
    type: Decimal.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(number) when is_integer(number) do
    number
    |> Decimal.new()
    |> encode_instance()
  end

  @impl EdgeDB.Protocol.Codec
  def encode_instance(number) when is_float(number) do
    number
    |> Decimal.from_float()
    |> encode_instance()
  end

  @impl EdgeDB.Protocol.Codec
  def encode_instance(%Decimal{coef: coef} = decimal) when not is_number(coef) do
    raise Errors.InvalidArgumentError,
          "unable to encode #{inspect(decimal)} as #{@type_name}: coef #{coef} is not a number"
  end

  @impl EdgeDB.Protocol.Codec
  def encode_instance(%Decimal{} = decimal) do
    sign = to_decimal_sign_enum(decimal.sign)
    scale = -decimal.exp

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
        decimal.coef * :math.pow(10, padding)
      else
        decimal.coef
      end

    number = trunc(number)

    digits = Integer.digits(number, @base)
    ndigits = length(digits)

    dscale = max(0, scale)
    weight = ndigits - scale_4digits - 1

    [
      Datatypes.UInt16.encode(ndigits),
      Datatypes.Int16.encode(weight),
      Enums.DecimalSign.encode(sign),
      Datatypes.UInt16.encode(dscale),
      Datatypes.UInt16.encode(digits, raw: true)
    ]
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(
        <<ndigits::uint16, weight::int16, sign::uint16, dscale::uint16, rest::binary>>
      )
      when Enums.DecimalSign.is_decimal_sign(sign) do
    {digits, <<>>} = Datatypes.UInt16.decode(ndigits, rest)

    number = Integer.undigits(digits, @base)

    decimals_stored = 4 * max(0, ndigits - weight - 1)
    {padding, number} = get_decimal_padding(number, dscale, decimals_stored)
    {scale, number} = get_decimal_scale(number, dscale, weight, ndigits, padding, decimals_stored)

    sign =
      sign
      |> Enums.DecimalSign.to_atom()
      |> to_decimal_sign()

    Decimal.new(sign, number, -scale)
  end

  @spec get_decimal_padding(
          number :: number(),
          scale :: integer(),
          decimals_stored :: integer()
        ) :: {integer(), number()}

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

  @spec get_decimal_scale(
          number :: number(),
          scale :: integer(),
          weight :: integer(),
          digits_count :: integer(),
          padding :: integer(),
          decimals_stored :: integer()
        ) :: {integer(), number()}

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

  @spec to_decimal_sign(:pos) :: 1
  defp to_decimal_sign(:pos) do
    1
  end

  @spec to_decimal_sign(:neg) :: -1
  defp to_decimal_sign(:neg) do
    -1
  end

  @spec to_decimal_sign_enum(1) :: :pos
  defp to_decimal_sign_enum(1) do
    :pos
  end

  @spec to_decimal_sign_enum(-1) :: :neg
  defp to_decimal_sign_enum(-1) do
    :neg
  end
end
