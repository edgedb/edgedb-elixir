defmodule EdgeDB.Query do
  defstruct [
    :statement,
    cardinality: :many,
    io_format: :binary,
    input_codec: nil,
    output_codec: nil,
    cached?: false
  ]
end

defimpl DBConnection.Query, for: EdgeDB.Query do
  def decode(_query, %EdgeDB.Result{decoded?: true}, _opts) do
    raise ArgumentError, "result has been decoded"
  end

  def decode(%EdgeDB.Query{output_codec: out_codec}, %EdgeDB.Result{} = result, _opts) do
    EdgeDB.Result.decode(result, out_codec)
  end

  def describe(query, _opts) do
    query
  end

  def encode(%EdgeDB.Query{input_codec: nil}, _params, _opts) do
    raise ArgumentError, "query hasn't been prepared"
  end

  def encode(%EdgeDB.Query{input_codec: in_codec}, params, _opts) do
    in_codec.encoder.(params)
  end

  def parse(%EdgeDB.Query{cached?: true}, _opts) do
    raise ArgumentError, "query has been prepared"
  end

  def parse(query, _opts) do
    query
  end
end
