testcases_file = "test/support/shared-client-testcases/project_path_hashing_testcases.json"

if File.exists?(testcases_file) do
  defmodule Tests.Shared.ProjectPathHashingTest do
    use Tests.Support.SharedCase, async: false

    alias EdgeDB.Connection.Config.Credentials

    @cases read_testcases(testcases_file)
    @moduletag :project_path_hashing

    for {testcase, index} <- Enum.with_index(@cases, 1) do
      @tag String.to_atom("shared_project_path_hasing_testcase_#{index}")

      describe "shared testcase for project path hashing ##{index}" do
        @tag testcase: testcase
        @tag debug: @debug_shared

        platform = testcase["platform"]

        cond do
          platform == "windows" and :os.type() != {:nt, :win32} ->
            @tag :skip

          platform == "macos" and :os.type() != {:unix, :darwin} ->
            @tag :skip

          platform == "linux" and :os.type() == {:unix, :darwin} ->
            @tag :skip

          true ->
            :ok
        end

        setup [
          :setup_debug,
          :setup_env,
          :transform_testcase_files,
          :setup_fs
        ]

        test "produces expected result", %{testcase: testcase} do
          %{
            "project" => project,
            "result" => result
          } = testcase

          assert result == Credentials.stash_dir(project)
        end
      end
    end

    defp transform_testcase_files(%{testcase: testcase}) do
      testcase = Map.put(testcase, "fs", %{"homedir" => testcase["homeDir"]})
      %{testcase: testcase}
    end
  end
else
  require Logger

  Logger.warn(
    "No EdgeDB shared testcases file for project path hashing was found, these tests will be skipped, " <>
      "to run shared tests clone project with submodules: " <>
      ~s("git clone --recursive <repository>") <> " or initialize submodule manually"
  )
end
