defmodule EdgeDB.Protocol.CustomCodec do
  @moduledoc since: "0.2.0"
  @moduledoc """
  Behaviour for custom scalar codecs.

  See custom codecs development guide on [hex.pm](https://hexdocs.pm/edgedb/custom-codecs.html)
    or on [edgedb.com](https://www.edgedb.com/docs/clients/elixir/custom-codecs) for more information.
  """

  alias EdgeDB.Protocol.Codec

  @doc since: "0.2.0"
  @doc """
  Initialize custom codec.
  """
  @callback new() :: Codec.t()

  @doc since: "0.2.0"
  @doc """
  Get name for type that can be decoded by codec.
  """
  @callback name() :: String.t()
end
