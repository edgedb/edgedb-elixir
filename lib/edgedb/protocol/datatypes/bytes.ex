defmodule EdgeDB.Protocol.Datatypes.Bytes do
  use EdgeDB.Protocol.Datatype

  defdatatype(type: bitstring())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(bytes) when is_bitstring(bytes) do
    [<<byte_size(bytes)::uint32>>, <<bytes::binary>>]
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<bytes_size::uint32, bytes::binary(bytes_size), rest::binary>>) do
    {bytes, rest}
  end
end
