defmodule EdgeDB.Protocol.Datatypes.UInt64 do
  @moduledoc false

  use EdgeDB.Protocol.Datatype

  @uint64_max 0xFFFFFFFFFFFFFFFF
  @uint64_min 0x0

  defguard is_uint64(number)
           when is_integer(number) and @uint64_min <= number and number <= @uint64_max

  defdatatype(type: non_neg_integer())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(number) when is_uint64(number) do
    <<number::uint64>>
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<number::uint64, rest::binary>>) do
    {number, rest}
  end
end
