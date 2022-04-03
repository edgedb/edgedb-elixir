defmodule EdgeDB.Protocol.BaseScalarCodec do
  @moduledoc false

  alias EdgeDB.Protocol.Codec

  @callback new() :: Codec.t()
  @callback id() :: String.t()
  @callback name() :: String.t()
end
