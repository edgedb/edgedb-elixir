defmodule EdgeDB.Protocol.Codecs.BigInt do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Codecs,
    DataTypes,
    Errors
  }

  @reserved 0

  defbasescalarcodec(
    type_name: "std::bigint",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-000000000110"),
    type: Decimal.t()
  )

  @spec encode_instance(t() | integer()) :: iodata()

  def encode_instance(%Decimal{exp: exp} = number) when exp != 0 do
    raise Errors.InvalidArgumentError,
          "unable to encode #{inspect(number)} as #{@type_name}: bigint numbers can't contain exponent"
  end

  def encode_instance(number) when is_float(number) do
    raise Errors.InvalidArgumentError,
          "unable to encode #{inspect(number)} as #{@type_name}: floats can't be encoded"
  end

  def encode_instance(decimal) do
    [ndigits, weight, sign, _dscale, digits] = Codecs.Decimal.encode_instance(decimal)
    [ndigits, weight, sign, DataTypes.UInt16.encode(@reserved), digits]
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(data) do
    Codecs.Decimal.decode_instance(data)
  end
end
