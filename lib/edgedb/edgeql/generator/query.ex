defmodule EdgeDB.EdgeQL.Generator.Query do
  @moduledoc false

  alias EdgeDB.EdgeQL.Generator.{
    Args,
    Shape
  }

  alias EdgeDB.Protocol.Enums

  defstruct [
    :file,
    :module,
    :query,
    :types,
    :args,
    :shape,
    :cardinality
  ]

  @type t() :: %__MODULE__{
          file: Path.t(),
          module: String.t(),
          query: String.t(),
          types: list({String.t(), {String.t(), String.t()}}),
          args: Args.t(),
          shape: Shape.t(),
          cardinality: Enums.cardinality()
        }
end

defimpl EdgeDB.EdgeQL.Generator.Render, for: EdgeDB.EdgeQL.Generator.Query do
  alias EdgeDB.EdgeQL.Generator.{
    Query,
    Render
  }

  require EEx

  @module_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "modules", "query.ex.eex"])
  EEx.function_from_file(:defp, :render_module_tpl, @module_tpl, [:assigns])

  @impl Render
  def render(%Query{} = query, :module, opts) do
    render_module_tpl(query: query, opts: opts)
  end
end

defimpl EdgeDB.EdgeQL.Generator.Handler, for: EdgeDB.EdgeQL.Generator.Query do
  alias EdgeDB.EdgeQL.Generator.{
    Query,
    Handler
  }

  require EEx

  @execute_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "handlers", "_execute.eex"])
  EEx.function_from_file(:defp, :render_execute_tpl, @execute_tpl, [])

  @single_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "handlers", "_single.eex"])
  EEx.function_from_file(:defp, :render_single_tpl, @single_tpl, [:assigns])

  @required_single_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "handlers", "_required_single.eex"])
  EEx.function_from_file(:defp, :render_required_single_tpl, @required_single_tpl, [:assigns])

  @multi_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "handlers", "_multi.eex"])
  EEx.function_from_file(:defp, :render_multi_tpl, @multi_tpl, [:assigns])

  @impl Handler
  def variable?(%Query{}) do
    true
  end

  @impl Handler
  def handle(query, opts \\ [])

  @impl Handler
  def handle(%Query{cardinality: :no_result}, _opts) do
    render_execute_tpl()
  end

  @impl Handler
  def handle(%Query{cardinality: :at_most_one} = query, opts) do
    render_single_tpl(query: query, opts: opts)
  end

  @impl Handler
  def handle(%Query{cardinality: :one} = query, opts) do
    render_required_single_tpl(query: query, opts: opts)
  end

  @impl Handler
  def handle(%Query{} = query, opts) do
    render_multi_tpl(query: query, opts: opts)
  end

  @impl Handler
  def handle?(%Query{}) do
    true
  end
end
