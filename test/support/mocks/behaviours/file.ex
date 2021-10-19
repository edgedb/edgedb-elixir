defmodule Tests.Support.Mocks.Behaviours.File do
  @callback cwd!() :: String.t()
  @callback read!(path :: Path.t()) :: binary()
  @callback exists?(path :: Path.t()) :: boolean()
  @callback exists?(path :: Path.t(), opts :: Keyword.t()) :: boolean()
end
