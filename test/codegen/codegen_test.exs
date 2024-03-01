defmodule Tests.CodegenTest do
  use Tests.Support.EdgeDBCase

  skip_before(version: 4, scope: :module)

  @queries_path Application.compile_env!(:edgedb, :generation)[:queries_path]

  queries =
    [@queries_path, "**", "*.edgeql"]
    |> Path.join()
    |> Path.wildcard()

  setup :edgedb_client

  describe "queries generation" do
    setup do
      {:ok, files} = EdgeDB.EdgeQL.Generator.generate(silent: true)

      Code.put_compiler_option(:ignore_module_conflict, true)

      on_exit(fn ->
        Code.put_compiler_option(:ignore_module_conflict, false)
      end)

      %{files: files}
    end

    test "codegen returns an atomized map for named tuple", %{client: client, files: files} do
      [{mod, _code}] =
        files
        |> Enum.find(fn {_query_file, elixir_file} ->
          String.contains?(elixir_file, "tuple/named/named.required")
        end)
        |> elem(1)
        |> Code.compile_file()

      assert %{a: "test", b: true} = mod.query!(client, arg: %{a: "test", b: true})
    end

    test "codegen returns an atom for an enum", %{client: client, files: files} do
      [{mod, _code}] =
        files
        |> Enum.find(fn {_query_file, elixir_file} ->
          String.contains?(elixir_file, "enum/named.required")
        end)
        |> elem(1)
        |> Code.compile_file()

      assert :A = mod.query!(client, arg: :A)
    end

    test "generated module equals the desired module state", %{files: files} do
      tasks =
        for query_path <- unquote(queries) do
          Task.async(fn ->
            assert %{^query_path => elixir_path} = files

            prepared_module =
              "#{query_path}.ex.assert"
              |> File.read!()
              |> Code.format_string!()
              |> IO.iodata_to_binary()

            generated_module =
              elixir_path
              |> File.read!()
              |> Code.format_string!()
              |> IO.iodata_to_binary()

            assert String.trim(prepared_module) == String.trim(generated_module)
            :ok
          end)
        end

      for result <- Task.await_many(tasks, :timer.seconds(10)) do
        assert :ok = result
      end
    end

    test "generated module compiles", %{files: files} do
      tasks =
        for query_path <- unquote(queries) do
          Task.async(fn ->
            assert %{^query_path => elixir_path} = files
            assert [{_module, _binary} | _rest] = Code.compile_file(elixir_path)
            :ok
          end)
        end

      for result <- Task.await_many(tasks, :timer.seconds(10)) do
        assert :ok = result
      end
    end
  end
end
