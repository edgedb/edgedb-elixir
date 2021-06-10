defmodule EdgeDB.Protocol.Datatypes.UInt16 do
  use EdgeDB.Protocol.Datatype

  @uint16_max 0xFFFF
  @uint16_min 0x0

  defguard is_uint16(number)
           when is_integer(number) and @uint16_min <= number and number <= @uint16_max

  defdatatype(type: non_neg_integer())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(number) when is_uint16(number) do
    <<number::uint16>>
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<number::uint16, rest::binary>>) do
    {number, rest}
  end
end
