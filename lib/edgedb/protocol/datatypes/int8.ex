defmodule EdgeDB.Protocol.Datatypes.Int8 do
  use EdgeDB.Protocol.Datatype

  @int8_max 0x7F
  @int8_min -0x80

  defguard is_int8(number)
           when is_integer(number) and @int8_min <= number and number <= @int8_max

  defdatatype(type: integer())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(number) when is_int8(number) do
    <<number::int8>>
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<number::int8, rest::binary>>) do
    {number, rest}
  end
end
