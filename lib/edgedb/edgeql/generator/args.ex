defmodule EdgeDB.EdgeQL.Generator.Args do
  @moduledoc false

  defmodule Arg do
    @moduledoc false

    alias EdgeDB.EdgeQL.Generator.{
      Array,
      Enum,
      NamedTuple,
      Range,
      Scalar,
      Tuple
    }

    defstruct [
      :name,
      :type,
      :is_optional
    ]

    @type t() :: %__MODULE__{
            name: String.t(),
            is_optional: boolean(),
            type:
              Array.t()
              | Enum.t()
              | NamedTuple.t()
              | Range.t()
              | Scalar.t()
              | Tuple.t()
          }
  end

  defstruct [
    :is_positional,
    :is_named,
    :is_empty,
    :args
  ]

  @type t() :: %__MODULE__{
          is_positional: boolean(),
          is_named: boolean(),
          is_empty: boolean(),
          args: list(Arg.t())
        }
end

defimpl EdgeDB.EdgeQL.Generator.Render, for: EdgeDB.EdgeQL.Generator.Args do
  alias EdgeDB.EdgeQL.Generator.{
    Args,
    Render
  }

  require EEx

  @keyword_typespec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_args_keyword.eex"])
  EEx.function_from_file(:defp, :render_keyword_typespec_tpl, @keyword_typespec_tpl, [:assigns])

  @map_typespec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_args_map.eex"])
  EEx.function_from_file(:defp, :render_map_typespec_tpl, @map_typespec_tpl, [:assigns])

  @spec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_args.eex"])
  EEx.function_from_file(:defp, :render_spec_tpl, @spec_tpl, [:assigns])

  @args_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "modules", "_args.eex"])
  EEx.function_from_file(:defp, :render_args_tpl, @args_tpl, [:assigns])

  def render(args, mode, opts \\ [])

  def render(%Args{is_named: true} = args, {:typespec, :keyword}, opts) do
    Render.Utils.render_to_line(&render_keyword_typespec_tpl/1, args: args, opts: opts)
  end

  def render(%Args{is_named: true} = args, {:typespec, :map}, opts) do
    Render.Utils.render_to_line(&render_map_typespec_tpl/1, args: args, opts: opts)
  end

  def render(%Args{is_positional: true} = args, :spec, opts) do
    Render.Utils.render_to_line(&render_spec_tpl/1, args: args, opts: opts)
  end

  def render(%Args{is_positional: true} = args, :args, opts) do
    Render.Utils.render_to_line(&render_args_tpl/1, args: args, opts: opts)
  end
end

defimpl EdgeDB.EdgeQL.Generator.Render, for: EdgeDB.EdgeQL.Generator.Args.Arg do
  alias EdgeDB.EdgeQL.Generator.{
    Args,
    Render
  }

  require EEx

  @typespec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_arg.eex"])
  EEx.function_from_file(:defp, :render_typespec_tpl, @typespec_tpl, [:assigns])

  @impl Render
  def render(%Args.Arg{} = arg, :typespec, opts \\ []) do
    Render.Utils.render_to_line(&render_typespec_tpl/1, arg: arg, opts: Keyword.merge(opts, root: true))
  end
end
