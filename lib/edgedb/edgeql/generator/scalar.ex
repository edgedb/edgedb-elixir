defmodule EdgeDB.EdgeQL.Generator.Scalar do
  @moduledoc false

  defstruct [
    :module,
    :typespec
  ]

  @type t() :: %__MODULE__{
          module: String.t(),
          typespec: String.t()
        }
end

defimpl EdgeDB.EdgeQL.Generator.Render, for: EdgeDB.EdgeQL.Generator.Scalar do
  alias EdgeDB.EdgeQL.Generator.{
    Scalar,
    Render
  }

  require EEx

  @typespec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_scalar.eex"])
  EEx.function_from_file(:defp, :render_typespec_tpl, @typespec_tpl, [:assigns], trim: true)

  @impl Render
  def render(%Scalar{} = scalar, :typespec, opts \\ []) do
    Render.Utils.render_to_line(&render_typespec_tpl/1, scalar: scalar, opts: opts)
  end
end

defimpl EdgeDB.EdgeQL.Generator.Handler, for: EdgeDB.EdgeQL.Generator.Scalar do
  alias EdgeDB.EdgeQL.Generator.{
    Scalar,
    Handler
  }

  @impl Handler
  def variable?(%Scalar{}) do
    false
  end

  @impl Handler
  def handle(%Scalar{}, _opts \\ []) do
    ""
  end

  @impl Handler
  def handle?(%Scalar{}) do
    false
  end
end
