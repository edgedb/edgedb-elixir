defmodule EdgeDB.EdgeQL.Generator.Shape do
  @moduledoc false

  alias EdgeDB.EdgeQL.Generator.{
    Array,
    Enum,
    Handler,
    NamedTuple,
    Object,
    Range,
    Scalar,
    Set,
    Tuple
  }

  defstruct [
    :is_multi,
    :is_optional,
    :type
  ]

  @type t() :: %__MODULE__{
          is_multi: boolean(),
          is_optional: boolean(),
          type:
            Array.t()
            | Enum.t()
            | NamedTuple.t()
            | Range.t()
            | Scalar.t()
            | Tuple.t()
            | Set.t()
            | Object.t()
        }

  @spec complex?(%__MODULE__{}) :: boolean()

  def complex?(%__MODULE__{type: %Object{}}) do
    true
  end

  def complex?(%__MODULE__{type: %Set{type: %Object{}}}) do
    true
  end

  def complex?(%__MODULE__{}) do
    false
  end
end

defimpl EdgeDB.EdgeQL.Generator.Render, for: EdgeDB.EdgeQL.Generator.Shape do
  alias EdgeDB.EdgeQL.Generator.{
    Shape,
    Set,
    Object,
    Render
  }

  require EEx

  @typespec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_shape.eex"])
  EEx.function_from_file(:defp, :render_typespec_tpl, @typespec_tpl, [:assigns])

  @impl Render
  def render(shape, mode, opts \\ [])

  @impl Render
  def render(%Shape{type: %Object{} = object}, :module, opts) do
    Render.render(object, :module, Keyword.merge(opts, module: "Result", root: false))
  end

  @impl Render
  def render(%Shape{type: %Set{type: %Object{} = object}}, :module, opts) do
    Render.render(object, :module, Keyword.merge(opts, module: "Result", root: false))
  end

  @impl Render
  def render(%Shape{type: %Object{}} = shape, :typespec, opts) do
    Render.Utils.render_to_line(&render_typespec_tpl/1,
      shape: shape,
      opts: Keyword.merge(opts, module: "Result", root: false)
    )
  end

  @impl Render
  def render(%Shape{type: %Set{type: %Object{}}} = shape, :typespec, opts) do
    Render.Utils.render_to_line(&render_typespec_tpl/1,
      shape: shape,
      opts: Keyword.merge(opts, module: "Result", root: false)
    )
  end

  @impl Render
  def render(%Shape{} = shape, :typespec, opts) do
    Render.Utils.render_to_line(&render_typespec_tpl/1, shape: shape, opts: Keyword.merge(opts, root: true))
  end
end

defimpl EdgeDB.EdgeQL.Generator.Handler, for: EdgeDB.EdgeQL.Generator.Shape do
  alias EdgeDB.EdgeQL.Generator.{
    Shape,
    Handler
  }

  require EEx

  @handler_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "handlers", "_shape.eex"])
  EEx.function_from_file(:defp, :render_handler_tpl, @handler_tpl, [:assigns])

  @impl Handler
  def variable?(%Shape{} = shape) do
    Handler.variable?(shape.type)
  end

  @impl Handler
  def handle(%Shape{} = shape, opts \\ []) do
    render_handler_tpl(shape: shape, opts: Keyword.put(opts, :module, "Result"))
  end

  @impl Handler
  def handle?(%Shape{} = shape) do
    Handler.handle?(shape.type)
  end
end
