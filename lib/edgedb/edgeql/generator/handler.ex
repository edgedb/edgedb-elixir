defprotocol EdgeDB.EdgeQL.Generator.Handler do
  @moduledoc false

  @spec variable?(t()) :: boolean()
  def variable?(entity)

  @spec handle(t(), Keyword.t()) :: iodata()
  def handle(entity, opts \\ [])

  @spec handle?(t()) :: boolean()
  def handle?(entity)
end

defmodule EdgeDB.EdgeQL.Generator.Handler.Utils do
  @moduledoc false

  alias EdgeDB.EdgeQL.Generator.Handler

  @spec variable(Handler.t(), String.t()) :: String.t()
  def variable(entity, var) do
    if Handler.variable?(entity) do
      var
    else
      "_#{var}"
    end
  end
end
