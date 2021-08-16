defmodule EdgeDB.Result do
  alias EdgeDB.Protocol.{
    Codec,
    Enums,
    Error
  }

  defstruct [
    :cardinality,
    set: EdgeDB.Set.new(),
    statement: nil,
    encoded_data: [],
    decoded?: false
  ]

  @type t() :: %__MODULE__{
          statement: String.t() | atom() | nil,
          cardinality: Enums.Cardinality.t(),
          set: EdgeDB.Set.t(),
          encoded_data: list(bitstring()),
          decoded?: boolean()
        }

  @spec new(Enums.Cardinality.t()) :: t()
  def new(cardinality) do
    %__MODULE__{cardinality: cardinality}
  end

  @spec closed_query() :: t()
  def closed_query do
    %__MODULE__{statement: :closed, cardinality: :no_result}
  end

  @spec add_encoded_data(t(), term()) :: t()
  def add_encoded_data(%__MODULE__{encoded_data: data} = result, element) do
    %__MODULE__{result | encoded_data: [element | data]}
  end

  @spec extract(t()) :: EdgeDB.Set.t() | term() | :ok

  def extract(%__MODULE__{cardinality: :at_most_one, set: set}) do
    if EdgeDB.Set.empty?(set) do
      raise Error.no_data_error("query didn't return any data")
    end

    set
    |> Enum.take(1)
    |> List.first()
  end

  def extract(%__MODULE__{cardinality: :many, set: set}) do
    set
  end

  def extract(%__MODULE__{cardinality: :no_result}) do
    :ok
  end

  @spec decode(t(), Codec.t()) :: t()

  def decode(%__MODULE__{cardinality: :no_result} = result, _codec) do
    %__MODULE__{result | decoded?: true}
  end

  def decode(%__MODULE__{} = result, codec) do
    result.encoded_data
    |> Enum.reverse()
    |> Enum.reduce(result, fn data, %__MODULE__{set: set} = result ->
      value = Codec.decode(codec, data)
      %__MODULE__{result | set: EdgeDB.Set.add(set, value)}
    end)
    |> Map.put(:encoded_data, nil)
    |> Map.put(:decoded?, true)
  end
end
