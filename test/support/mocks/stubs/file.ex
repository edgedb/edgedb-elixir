defmodule Tests.Support.Mocks.Stubs.FileStub do
  @behaviour Tests.Support.Mocks.Behaviours.File

  defdelegate cwd!(), to: File
  defdelegate read!(path), to: File
  defdelegate exists?(path, opts \\ []), to: File
end
