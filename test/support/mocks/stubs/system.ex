defmodule Tests.Support.Mocks.Stubs.SystemStub do
  @behaviour Tests.Support.Mocks.Behaviours.System

  defdelegate user_home!(), to: System
  defdelegate get_env(name, default \\ nil), to: System
end
