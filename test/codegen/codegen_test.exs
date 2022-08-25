defmodule Tests.CodegenTest do
  use Tests.Support.EdgeDBCase

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

    test "codegen returns a complex shape as atomized maps", %{client: client} do
      e = "arg"
      f = 42

      assert %{
               a: 1,
               b: %{
                 b_a: 2,
                 b_b: 3
               },
               c: "hello world",
               d: [4, 5, 6],
               e: ^e,
               f: ^f
             } =
               Tests.Codegen.Queries.Standart.SelectStartartTypesNamedSimple.query!(client,
                 e: e,
                 f: f
               )
    end

    for query_path <- queries do
      test "for #{query_path} equals the desired module state", %{files: files} do
        assert %{unquote(query_path) => elixir_path} = files
        prepared_module = File.read!("#{unquote(query_path)}.ex.assert")
        generated_module = File.read!(elixir_path)
        assert String.trim(prepared_module) == String.trim(generated_module)
      end

      test "for #{query_path} compiles", %{files: files} do
        assert %{unquote(query_path) => elixir_path} = files
        Code.compile_file(elixir_path)
        :ok
      end
    end
  end
end
