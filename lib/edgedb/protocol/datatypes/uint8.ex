defmodule EdgeDB.Protocol.Datatypes.UInt8 do
  use EdgeDB.Protocol.Datatype

  @uint8_max 0xFF
  @uint8_min 0x0

  defguard is_uint8(number)
           when is_integer(number) and @uint8_min <= number and number <= @uint8_max

  defdatatype(type: non_neg_integer())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(number) when is_uint8(number) do
    <<number::uint8>>
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<number::uint8, rest::binary>>) do
    {number, rest}
  end
end
