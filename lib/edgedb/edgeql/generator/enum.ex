defmodule EdgeDB.EdgeQL.Generator.Enum do
  @moduledoc false

  defstruct [
    :module,
    :typespec,
    :members,
    :atomize
  ]

  @type t() :: %__MODULE__{
          module: String.t(),
          typespec: String.t(),
          members: list(String.t()),
          atomize: boolean()
        }
end

defimpl EdgeDB.EdgeQL.Generator.Render, for: EdgeDB.EdgeQL.Generator.Enum do
  alias EdgeDB.EdgeQL.Generator.{
    Enum,
    Render
  }

  require EEx

  @typespec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_enum.eex"])
  EEx.function_from_file(:defp, :render_typespec_tpl, @typespec_tpl, [:assigns])

  @impl Render
  def render(%Enum{} = enum, :typespec, opts \\ []) do
    Render.Utils.render_to_line(&render_typespec_tpl/1, enum: enum, opts: opts)
  end
end

defimpl EdgeDB.EdgeQL.Generator.Handler, for: EdgeDB.EdgeQL.Generator.Enum do
  alias EdgeDB.EdgeQL.Generator.{
    Enum,
    Render,
    Handler
  }

  require EEx

  @handler_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "handlers", "_enum.eex"])
  EEx.function_from_file(:defp, :render_handler_tpl, @handler_tpl, [:assigns])

  @impl Handler
  def variable?(%Enum{}) do
    true
  end

  @impl Handler
  def handle(%Enum{} = enum, opts \\ []) do
    Render.Utils.render_with_trim(&render_handler_tpl/1, enum: enum, opts: opts)
  end

  @impl Handler
  def handle?(%Enum{atomize: atomize?}) do
    atomize?
  end
end
