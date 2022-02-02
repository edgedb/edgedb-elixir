defmodule EdgeDB.Protocol.Datatypes.Int64 do
  @moduledoc false

  use EdgeDB.Protocol.Datatype

  @int64_max 0x7FFFFFFFFFFFFFFF
  @int64_min -0x8000000000000000

  defguard is_int64(number)
           when is_integer(number) and @int64_min <= number and number <= @int64_max

  defdatatype(type: integer())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(number) when is_int64(number) do
    <<number::int64>>
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<number::int64, rest::binary>>) do
    {number, rest}
  end
end
