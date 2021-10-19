defmodule Tests.Support.Mocks.Stubs.PathStub do
  @behaviour Tests.Support.Mocks.Behaviours.Path

  defdelegate basename(path), to: Path
  defdelegate expand(path), to: Path
  defdelegate type(path), to: Path
  defdelegate join(paths), to: Path
  defdelegate join(left, right), to: Path
end
