defmodule Tests.Support.Mocks.Behaviours.System do
  @callback user_home!() :: String.t()
  @callback get_env(name :: String.t()) :: String.t() | nil
  @callback get_env(name :: String.t(), default :: String.t() | nil) :: String.t() | nil
end
