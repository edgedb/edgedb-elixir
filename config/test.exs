import Config

config :edgedb,
  rended_colored_errors: false,
  file_module: Tests.Support.Mocks.FileMock,
  path_module: Tests.Support.Mocks.PathMock,
  system_module: Tests.Support.Mocks.SystemMock
