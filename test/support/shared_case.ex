# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Tests.Support.SharedCase do
  use ExUnit.CaseTemplate

  import Mox

  alias Tests.Support.Mocks

  require Logger

  using do
    quote do
      import Mox

      import Tests.Support.EdgeDBCase

      import unquote(__MODULE__)

      @debug_shared System.get_env("EDGEDB_SHARED_TESTS_DEBUG", "") != ""

      @moduletag :shared
      @moduletag capture_log: !@debug_shared

      setup [
        :setup_stubs_fallbacks,
        :verify_on_exit!
      ]
    end
  end

  def read_testcases(cases_path) do
    cases_path |> File.read!() |> Jason.decode!()
  end

  def setup_debug(%{debug: true}) do
    Logger.configure(level: :debug)
  end

  def setup_debug(_context) do
    :ok
  end

  def setup_env(%{testcase: %{"env" => env}}) do
    Logger.debug("configure environment variables: #{inspect(env)}")

    original_env = System.get_env()

    original_env_keys =
      original_env
      |> Map.keys()
      |> MapSet.new()

    on_exit(fn ->
      exit_env = System.get_env()

      exit_env_keys =
        exit_env
        |> Map.keys()
        |> MapSet.new()

      external_keys = MapSet.difference(exit_env_keys, original_env_keys)

      for key <- external_keys do
        System.delete_env(key)
      end

      for {key, value} <- original_env do
        System.put_env(key, value)
      end
    end)

    for key <- original_env_keys do
      System.delete_env(key)
    end

    for {key, value} <- env do
      System.put_env(key, value)
    end

    :ok
  end

  def setup_env(_context) do
    Logger.debug("configure environment variables to pretend that $XDG_CONFIG_HOME doesn't exist")

    if xdg_config_dir = System.get_env("XDG_CONFIG_HOME") do
      System.delete_env("XDG_CONFIG_HOME")

      on_exit(fn ->
        System.put_env("XDG_CONFIG_HOME", xdg_config_dir)
      end)
    end

    :ok
  end

  def setup_fs(%{testcase: %{"fs" => fs_mapping}}) do
    Logger.debug("configure files: #{inspect(fs_mapping)}")

    stub(Mocks.FileMock, :stat!, fn _path ->
      %File.Stat{
        major_device: 0
      }
    end)

    with %{"cwd" => cwd} <- fs_mapping do
      stub(Mocks.FileMock, :cwd!, fn ->
        cwd
      end)
    end

    with %{"homedir" => homedir} <- fs_mapping do
      stub(Mocks.SystemMock, :user_home!, fn ->
        homedir
      end)
    end

    with %{"files" => files} <- fs_mapping do
      files =
        Enum.reduce(files, %{}, fn {file, data}, files ->
          if String.contains?(file, "${HASH}") do
            hash =
              :sha
              |> :crypto.hash(data["project-path"])
              |> Base.encode16(case: :lower)

            dir = String.replace(file, "${HASH}", hash)
            instance = Path.join(dir, "instance-name")
            profile = Path.join(dir, "cloud-profile")
            project = Path.join(dir, "project-path")

            files
            |> Map.put(dir, "")
            |> Map.put(instance, data["instance-name"])
            |> Map.put(profile, data["cloud-profile"])
            |> Map.put(project, data["project-path"])
          else
            Map.put(files, file, data)
          end
        end)

      stub(Mocks.FileMock, :exists?, fn path ->
        not is_nil(files[path])
      end)

      stub(Mocks.FileMock, :exists?, fn path, _opts ->
        not is_nil(files[path])
      end)

      stub(Mocks.FileMock, :read!, fn path ->
        if data = files[path] do
          data
        else
          raise File.Error, action: "read", path: path, reason: :enoent
        end
      end)

      stub(Mocks.PathMock, :expand, fn path ->
        path
      end)
    end

    :ok
  end

  def setup_fs(_context) do
    Logger.debug("configure files so that `edgedb.toml` won't exist")

    stub(Mocks.FileMock, :exists?, fn path ->
      if path == Path.join(File.cwd!(), "edgedb.toml") do
        false
      else
        File.exists?(path)
      end
    end)

    stub(Mocks.FileMock, :exists?, fn path, _opts ->
      if path == Path.join(File.cwd!(), "edgedb.toml") do
        false
      else
        File.exists?(path)
      end
    end)

    :ok
  end
end
