if File.exists?("test/support/shared-client-testcases/connection_testcases.json") do
  defmodule Tests.Shared.ConnectionCase do
    use Tests.Support.EdgeDBCase, async: false

    alias EdgeDB.Connection.Config

    alias Tests.Support.Mocks

    @case_to_driver_errors %{
      "credentials_file_not_found" => {RuntimeError, message: ~r/could not read/},
      "project_not_initialised" =>
        {EdgeDB.Protocol.Error,
         name: "ClientConnectionError",
         message: ~r/found "edgedb.toml" but the project is not initialized/},
      "no_options_or_toml" =>
        {EdgeDB.Protocol.Error,
         name: "ClientConnectionError",
         message: ~r/no "edgedb.toml" found and no connection options specified/},
      "invalid_credentials_file" => {RuntimeError, message: ~r/invalid credentials/},
      "invalid_instance_name" => {RuntimeError, message: ~r/invalid instance name/},
      "invalid_dsn" => {RuntimeError, message: ~r/invalid DSN/},
      "unix_socket_unsupported" => {RuntimeError, message: ~r/unix socket paths not supported/},
      "invalid_host" => {RuntimeError, message: ~r/invalid host/},
      "invalid_port" => {RuntimeError, message: ~r/invalid port/},
      "invalid_user" => {RuntimeError, message: ~r/invalid user/},
      "invalid_database" => {RuntimeError, message: ~r/invalid database/},
      "multiple_compound_env" => {
        EdgeDB.Protocol.Error,
        name: "ClientConnectionError",
        message: ~r/can not have more than one of the following connection environment variables/
      },
      "multiple_compound_opts" => {
        EdgeDB.Protocol.Error,
        name: "ClientConnectionError",
        message: ~r/can not have more than one of the following connection options/
      },
      "env_not_found" => {RuntimeError, message: ~r/environment variable ".*" doesn't exist/},
      "file_not_found" => {File.Error, message: ~r/could not read/},
      "invalid_tls_verify_hostname" => {
        RuntimeError,
        message: ~r"tls_verify_hostname can only be one of yes/no"
      }
    }
    @known_case_errors Map.keys(@case_to_driver_errors)

    @shared_cases_file "test/support/shared-client-testcases/connection_testcases.json"
    @cases @shared_cases_file |> File.read!() |> Jason.decode!()

    @moduletag :shared

    for {testcase, index} <- Enum.with_index(@cases, 1) do
      @tag String.to_atom("shared_testcase_#{index}")

      with %{"fs" => fs_mapping} when map_size(fs_mapping) != 0 <- testcase do
        platform = testcase["platform"]

        cond do
          platform == "windows" or :os.type() == {:nt, :win32} ->
            @tag :skip

          platform == "macos" and :os.type() != {:unix, :darwin} ->
            @tag :skip

          is_nil(platform) and :os.type() == {:unix, :darwin} ->
            @tag :skip

          true ->
            :ok
        end
      end

      describe "shared testcase for connection options parsing ##{index}" do
        @tag testcase: testcase

        setup [
          :setup_env,
          :setup_fs,
          :setup_opts,
          :setup_error,
          :setup_result
        ]

        test "produces expected result", %{opts: opts, execution_callback: callback} do
          callback.(fn ->
            Config.connect_opts(opts)
          end)
        end
      end
    end

    defp setup_env(%{testcase: %{"env" => env}}) do
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

    defp setup_env(_context) do
      :ok
    end

    defp setup_fs(%{testcase: %{"fs" => fs_mapping}}) do
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
        stub(Mocks.FileMock, :exists?, fn path ->
          Map.has_key?(files, path)
        end)

        stub(Mocks.FileMock, :exists?, fn path, _opts ->
          Map.has_key?(files, path)
        end)

        stub(Mocks.FileMock, :read!, fn path ->
          if data = files[path] do
            data
          else
            raise File.Error, action: "read", path: path, reason: :enoent
          end
        end)
      end

      :ok
    end

    defp setup_fs(_context) do
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

    defp setup_opts(%{testcase: %{"opts" => opts}}) do
      %{
        opts:
          Enum.reject(
            [
              dsn: opts["dsn"],
              credentials_file: opts["credentialsFile"],
              host: opts["host"],
              port: opts["port"],
              database: opts["database"],
              user: opts["user"],
              password: opts["password"],
              tls_ca_file: opts["tlsCAFile"],
              tls_verify_hostname: opts["tlsVerifyHostname"],
              timeout: opts["timeout"],
              server_settings: opts["serverSettings"]
            ],
            fn {_key, value} ->
              is_nil(value)
            end
          )
      }
    end

    defp setup_opts(_context) do
      %{opts: []}
    end

    defp setup_error(%{testcase: %{"error" => _error, "result" => _result} = testcase}) do
      raise RuntimeError,
        message:
          ~s(invalid test case: either "result" or "error" key to be specified, ) <>
            "testcase: #{inspect(testcase)}"
    end

    defp setup_error(%{testcase: %{"error" => %{"type" => type}} = testcase})
         when type not in @known_case_errors do
      raise RuntimeError,
        message: "unknown error type: #{type}, testcase: #{inspect(testcase)}"
    end

    defp setup_error(%{testcase: %{"error" => %{"type" => error_type}}}) do
      {error, opts} = @case_to_driver_errors[error_type]

      expected_to_fail_callback = fn callback ->
        {message, opts} = Keyword.pop!(opts, :message)

        raised_error =
          assert_raise error, message, fn ->
            callback.()
          end

        for {attribute, value} <- opts do
          assert Map.get(raised_error, attribute) == value
        end
      end

      %{execution_callback: expected_to_fail_callback}
    end

    defp setup_error(%{testcase: %{"result" => _result}}) do
      :ok
    end

    defp setup_error(%{testcase: testcase}) do
      raise RuntimeError,
        message:
          ~s(invalid test case: either "result" or "error" key has to be specified, ) <>
            "got both, testcase: #{inspect(testcase)}"
    end

    defp setup_result(%{testcase: %{"result" => result} = testcase}) do
      expected_result =
        Enum.reject(
          [
            address: List.to_tuple(result["address"]),
            database: result["database"],
            user: result["user"],
            password: result["password"],
            tls_ca_data: result["tlsCAData"],
            tls_verify_hostname: result["tlsVerifyHostname"],
            server_settings: result["serverSettings"]
          ],
          fn {_key, value} ->
            is_nil(value)
          end
        )

      expected_to_success_callback = fn callback ->
        parsed_opts = callback.()

        parsed_opts = Keyword.take(parsed_opts, Keyword.keys(expected_result))

        assert Keyword.equal?(parsed_opts, expected_result),
               "wrong parsed connect opts, expected: #{inspect(expected_result)}, " <>
                 "got: #{inspect(parsed_opts)}, failed testcase: #{inspect(testcase)}"
      end

      %{execution_callback: expected_to_success_callback}
    end

    defp setup_result(_context) do
      :ok
    end
  end
else
  require Logger

  Logger.warn(
    "No EdgeDB shared testcases file for connection options was found, these tests will be skipped, " <>
      "to run shared tests clone project with submodules: " <>
      ~s("git clone --recursive <repository>") <> " or initialize submodule manually"
  )
end
