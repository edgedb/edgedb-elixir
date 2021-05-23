defmodule EdgeDB.Query do
  defstruct [
    :statement,
    cardinality: :many,
    io_format: :binary,
    input_codec: nil,
    output_codec: nil,
    cached?: false,
    params: []
  ]

  @type t() :: %__MODULE__{}
  @type params() :: list()
  @type query_opts :: list()

  @spec new(String.t(), params(), query_opts()) :: t()
  def new(statement, params, opts \\ []) do
    %__MODULE__{
      statement: statement,
      cardinality: Keyword.get(opts, :cardinality, :many),
      io_format: Keyword.get(opts, :io_format, :binary),
      params: params
    }
  end
end

defimpl DBConnection.Query, for: EdgeDB.Query do
  @impl DBConnection.Query

  def decode(_query, %EdgeDB.Result{decoded?: true}, _opts) do
    raise EdgeDB.Protocol.Errors.InterfaceError, "result has been decoded"
  end

  def decode(%EdgeDB.Query{output_codec: out_codec}, %EdgeDB.Result{} = result, _opts) do
    EdgeDB.Result.decode(result, out_codec)
  end

  @impl DBConnection.Query
  def describe(query, _opts) do
    query
  end

  @impl DBConnection.Query

  def encode(%EdgeDB.Query{input_codec: nil}, _params, _opts) do
    raise EdgeDB.Protocol.Errors.InterfaceError, "query hasn't been prepared"
  end

  def encode(%EdgeDB.Query{input_codec: in_codec}, params, _opts) do
    in_codec.encoder.(params)
  end

  @impl DBConnection.Query

  def parse(%EdgeDB.Query{cached?: true}, _opts) do
    raise EdgeDB.Protocol.Errors.InterfaceError, "query has been prepared"
  end

  def parse(query, _opts) do
    query
  end
end
