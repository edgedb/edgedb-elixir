defprotocol EdgeDB.EdgeQL.Generator.Render do
  @moduledoc false

  @spec render(t(), term(), Keyword.t()) :: iodata()
  def render(entity, mode, opts \\ [])
end

defmodule EdgeDB.EdgeQL.Generator.Render.Utils do
  @moduledoc false

  @spec render_with_trim((Keyword.t() -> iodata()), Keyword.t()) :: iodata()
  def render_with_trim(renderer, opts) do
    opts
    |> renderer.()
    |> String.trim()
  end

  @spec render_to_line((Keyword.t() -> iodata()), Keyword.t()) :: iodata()
  def render_to_line(renderer, opts) do
    renderer
    |> render_with_trim(opts)
    |> String.split("\n")
    |> Enum.join(" ")
  end
end
