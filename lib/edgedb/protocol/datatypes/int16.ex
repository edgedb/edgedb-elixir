defmodule EdgeDB.Protocol.Datatypes.Int16 do
  @moduledoc false

  use EdgeDB.Protocol.Datatype

  @int16_max 0x7FFF
  @int16_min -0x8000

  defguard is_int16(number)
           when is_integer(number) and @int16_min <= number and number <= @int16_max

  defdatatype(type: integer())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(number) when is_int16(number) do
    <<number::int16>>
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<number::int16, rest::binary>>) do
    {number, rest}
  end
end
