import Config

config :edgedb,
  file_module: Tests.Support.Mocks.FileMock,
  path_module: Tests.Support.Mocks.PathMock,
  system_module: Tests.Support.Mocks.SystemMock
