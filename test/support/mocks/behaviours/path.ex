defmodule Tests.Support.Mocks.Behaviours.Path do
  @callback basename(path :: Path.t()) :: String.t()
  @callback expand(path :: Path.t()) :: String.t()
  @callback type(path :: Path.t()) :: :absolute | :relative | :volumerelative
  @callback join(paths :: list(Path.t())) :: String.t()
  @callback join(left :: Path.t(), right :: Path.t()) :: String.t()
  @callback dirname(path :: Path.t()) :: String.t()
end
