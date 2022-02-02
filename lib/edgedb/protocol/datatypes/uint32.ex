defmodule EdgeDB.Protocol.Datatypes.UInt32 do
  @moduledoc false

  use EdgeDB.Protocol.Datatype

  @uint32_max 0xFFFFFFFF
  @uint32_min 0x0

  defguard is_uint32(number)
           when is_integer(number) and @uint32_min <= number and number <= @uint32_max

  defdatatype(type: non_neg_integer())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(number) when is_uint32(number) do
    <<number::uint32>>
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<number::uint32, rest::binary>>) do
    {number, rest}
  end
end
