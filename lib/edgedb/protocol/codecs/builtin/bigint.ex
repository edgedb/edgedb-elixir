defmodule EdgeDB.Protocol.Codecs.Builtin.BigInt do
  @moduledoc false

  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes
  }

  @reserved 0

  defbuiltinscalarcodec(
    type_name: "std::bigint",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000110"),
    type: Decimal.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(%Decimal{exp: exp} = number) when exp != 0 do
    raise EdgeDB.Error.invalid_argument_error(
            "unable to encode #{inspect(number)} as #{type_name()}: bigint numbers can't contain exponent"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def encode_instance(number) when is_float(number) do
    raise EdgeDB.Error.invalid_argument_error(
            "unable to encode #{inspect(number)} as #{type_name()}: floats can't be encoded"
          )
  end

  @impl EdgeDB.Protocol.Codec
  def encode_instance(number) do
    [ndigits, weight, sign, _dscale, digits] = Codecs.Builtin.Decimal.encode_instance(number)
    [ndigits, weight, sign, Datatypes.UInt16.encode(@reserved), digits]
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(data) do
    Codecs.Builtin.Decimal.decode_instance(data)
  end
end
