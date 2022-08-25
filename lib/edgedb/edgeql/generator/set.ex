defmodule EdgeDB.EdgeQL.Generator.Set do
  @moduledoc false

  alias EdgeDB.EdgeQL.Generator.{
    Array,
    Enum,
    NamedTuple,
    Object,
    Range,
    Scalar,
    Tuple
  }

  defstruct [
    :type
  ]

  @type t() :: %__MODULE__{
          type:
            Array.t()
            | Enum.t()
            | NamedTuple.t()
            | Range.t()
            | Scalar.t()
            | Tuple.t()
            | Object.t()
        }
end

defimpl EdgeDB.EdgeQL.Generator.Render, for: EdgeDB.EdgeQL.Generator.Set do
  alias EdgeDB.EdgeQL.Generator.{
    Object,
    Set,
    Render
  }

  require EEx

  @typespec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_set.eex"])
  EEx.function_from_file(:defp, :render_typespec_tpl, @typespec_tpl, [:assigns], trim: true)

  @impl Render
  def render(set, mode, opts \\ [])

  @impl Render
  def render(%Set{type: %Object{} = object}, :module, opts) do
    EdgeDB.EdgeQL.Generator.Render.render(object, :module, opts)
  end

  @impl Render
  def render(%Set{} = set, :typespec, opts) do
    Render.Utils.render_to_line(&render_typespec_tpl/1, set: set, opts: opts)
  end
end

defimpl EdgeDB.EdgeQL.Generator.Handler, for: EdgeDB.EdgeQL.Generator.Set do
  alias EdgeDB.EdgeQL.Generator.{
    Set,
    Handler
  }

  require EEx

  @handler_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "handlers", "_set.eex"])
  EEx.function_from_file(:defp, :render_handler_tpl, @handler_tpl, [:assigns])

  @impl Handler
  def variable?(%Set{} = set) do
    Handler.variable?(set.type)
  end

  @impl Handler
  def handle(%Set{} = set, opts \\ []) do
    render_handler_tpl(set: set, opts: opts)
  end

  @impl Handler
  def handle?(%Set{} = set) do
    Handler.handle?(set.type)
  end
end
