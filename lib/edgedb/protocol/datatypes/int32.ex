defmodule EdgeDB.Protocol.Datatypes.Int32 do
  use EdgeDB.Protocol.Datatype

  @int32_max 0x7FFFFFFF
  @int32_min -0x80000000

  defguard is_int32(number)
           when is_integer(number) and @int32_min <= number and number <= @int32_max

  defdatatype(type: integer())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(number) when is_int32(number) do
    <<number::int32>>
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<number::int32, rest::binary>>) do
    {number, rest}
  end
end
