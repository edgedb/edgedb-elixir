defmodule EdgeDB.EdgeQL.Generator.Object do
  @moduledoc false

  defmodule Property do
    @moduledoc false

    alias EdgeDB.EdgeQL.Generator.{
      Array,
      Enum,
      NamedTuple,
      Object,
      Range,
      Scalar,
      Set,
      Tuple
    }

    defstruct [
      :name,
      :is_multi,
      :is_optional,
      :is_link_property,
      :index,
      :type
    ]

    @type t() :: %__MODULE__{
            name: String.t(),
            is_multi: boolean(),
            is_optional: boolean(),
            is_link_property: boolean(),
            index: non_neg_integer(),
            type:
              Array.t()
              | Enum.t()
              | NamedTuple.t()
              | Range.t()
              | Scalar.t()
              | Tuple.t()
              | Set.t()
          }
  end

  defmodule Link do
    @moduledoc false

    alias EdgeDB.EdgeQL.Generator.{
      Array,
      Enum,
      NamedTuple,
      Object,
      Range,
      Scalar,
      Set,
      Tuple
    }

    defstruct [
      :name,
      :is_multi,
      :is_optional,
      :index,
      :type
    ]

    @type t() :: %__MODULE__{
            name: String.t(),
            is_multi: boolean(),
            is_optional: boolean(),
            index: non_neg_integer(),
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
  end

  defstruct [
    :properties,
    :links
  ]

  @type t() :: %__MODULE__{
          properties: list(Property.t()),
          links: list(Link.t())
        }
end

defimpl EdgeDB.EdgeQL.Generator.Render, for: EdgeDB.EdgeQL.Generator.Object do
  alias EdgeDB.EdgeQL.Generator.{
    Object,
    Render
  }

  require EEx

  @module_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "modules", "_object.eex"])
  EEx.function_from_file(:defp, :render_module_tpl, @module_tpl, [:assigns])

  @typespec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_object.eex"])
  EEx.function_from_file(:defp, :render_typespec_tpl, @typespec_tpl, [:assigns])

  @impl Render
  def render(object, mode, opts \\ [])

  @impl Render
  def render(%Object{} = object, :module, opts) do
    render_module_tpl(object: object, opts: opts)
  end

  @impl Render
  def render(%Object{} = object, :typespec, opts) do
    Render.Utils.render_to_line(&render_typespec_tpl/1, object: object, opts: opts)
  end
end

defimpl EdgeDB.EdgeQL.Generator.Render, for: EdgeDB.EdgeQL.Generator.Object.Link do
  alias EdgeDB.EdgeQL.Generator.{
    Object,
    Render
  }

  require EEx

  @module_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "modules", "_link.eex"])
  EEx.function_from_file(:defp, :render_module_tpl, @module_tpl, [:assigns])

  @typespec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_link.eex"])
  EEx.function_from_file(:defp, :render_typespec_tpl, @typespec_tpl, [:assigns])

  @impl Render
  def render(link, mode, opts \\ [])

  @impl Render
  def render(%Object.Link{} = link, :module, opts) do
    render_module_tpl(link: link, opts: Keyword.put(opts, :module, Macro.camelize(link.name)))
  end

  @impl Render
  def render(%Object.Link{} = link, :typespec, opts) do
    Render.Utils.render_to_line(&render_typespec_tpl/1,
      link: link,
      opts: Keyword.put(opts, :module, Macro.camelize(link.name))
    )
  end
end

defimpl EdgeDB.EdgeQL.Generator.Render, for: EdgeDB.EdgeQL.Generator.Object.Property do
  alias EdgeDB.EdgeQL.Generator.{
    Object,
    Render
  }

  require EEx

  @typespec_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "typespecs", "_property.eex"])
  EEx.function_from_file(:defp, :render_typespec_tpl, @typespec_tpl, [:assigns])

  @impl Render
  def render(%Object.Property{} = property, :typespec, opts \\ []) do
    Render.Utils.render_to_line(&render_typespec_tpl/1, property: property, opts: opts)
  end
end

defimpl EdgeDB.EdgeQL.Generator.Handler, for: EdgeDB.EdgeQL.Generator.Object do
  alias EdgeDB.EdgeQL.Generator.{
    Object,
    Render,
    Handler
  }

  require EEx

  @handler_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "handlers", "_object.eex"])
  EEx.function_from_file(:defp, :render_handler_tpl, @handler_tpl, [:assigns])

  @impl Handler
  def variable?(%Object{properties: [], links: []}) do
    false
  end

  @impl Handler
  def variable?(%Object{}) do
    true
  end

  @impl Handler
  def handle(%Object{} = object, opts \\ []) do
    Render.Utils.render_with_trim(&render_handler_tpl/1, object: object, opts: opts)
  end

  @impl Handler
  def handle?(%Object{}) do
    true
  end
end

defimpl EdgeDB.EdgeQL.Generator.Handler, for: EdgeDB.EdgeQL.Generator.Object.Property do
  alias EdgeDB.EdgeQL.Generator.{
    Render,
    Handler,
    Object
  }

  require EEx

  @handler_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "handlers", "_property.eex"])
  EEx.function_from_file(:defp, :render_handler_tpl, @handler_tpl, [:assigns])

  @impl Handler
  def variable?(%Object.Property{} = property) do
    Handler.variable?(property.type)
  end

  @impl Handler
  def handle(%Object.Property{} = property, opts \\ []) do
    Render.Utils.render_with_trim(&render_handler_tpl/1, property: property, opts: opts)
  end

  @impl Handler
  def handle?(%Object.Property{} = property) do
    Handler.handle?(property.type)
  end
end

defimpl EdgeDB.EdgeQL.Generator.Handler, for: EdgeDB.EdgeQL.Generator.Object.Link do
  alias EdgeDB.EdgeQL.Generator.{
    Object,
    Render,
    Handler
  }

  require EEx

  @handler_tpl Path.join([:code.priv_dir(:edgedb), "codegen", "templates", "handlers", "_link.eex"])
  EEx.function_from_file(:defp, :render_handler_tpl, @handler_tpl, [:assigns])

  @impl Handler
  def variable?(%Object.Link{} = link) do
    Handler.variable?(link.type)
  end

  @impl Handler
  def handle(%Object.Link{} = link, opts \\ []) do
    module = Enum.map_join([opts[:module], link.name], ".", &Macro.camelize/1)
    Render.Utils.render_with_trim(&render_handler_tpl/1, link: link, opts: Keyword.put(opts, :module, module))
  end

  @impl Handler
  def handle?(%Object.Link{}) do
    true
  end
end
