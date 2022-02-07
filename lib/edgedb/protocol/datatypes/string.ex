defmodule EdgeDB.Protocol.Datatypes.String do
  @moduledoc false

  use EdgeDB.Protocol.Datatype

  defdatatype(type: String.t())

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(string) when is_binary(string) do
    [<<byte_size(string)::uint32>>, <<string::binary>>]
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<string_size::uint32, string::binary(string_size), rest::binary>>) do
    {string, rest}
  end
end
