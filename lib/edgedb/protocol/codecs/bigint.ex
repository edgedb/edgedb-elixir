defmodule EdgeDB.Protocol.Codecs.BigInt do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Codecs,
    DataTypes
  }

  @reserved 0

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-000000000110"),
    type_name: "std::bigint",
    type: Decimal.t()
  )

  @spec encode_instance(t() | integer() | float()) :: iodata()

  def encode_instance(%Decimal{exp: exp}) when exp != 0 do
    raise EdgeDB.Protocol.Errors.InvalidArgumentError, "bigint numbers cannot contain exponent"
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
