defmodule EdgeDB.Connection.InternalRequest do
  @moduledoc false

  defstruct [
    :request
  ]
end

defimpl DBConnection.Query, for: EdgeDB.Connection.InternalRequest do
  @impl DBConnection.Query
  def decode(_query, result, _opts) do
    result
  end

  @impl DBConnection.Query
  def describe(query, _opts) do
    query
  end

  @impl DBConnection.Query
  def encode(_query, params, _opts) do
    params
  end

  @impl DBConnection.Query
  def parse(query, _opts) do
    query
  end
end
