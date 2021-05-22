defmodule EdgeDB.Result do
  alias EdgeDB.Protocol.{
    Codec,
    Enums
  }

  defstruct [
    :statement,
    :cardinality,
    :set,
    encoded_data: [],
    decoded?: false
  ]

  @type t() :: %__MODULE__{}

  @spec new(Enums.Cardinality.t()) :: t()
  def new(cardinality) do
    %__MODULE__{cardinality: cardinality, set: EdgeDB.Set.new()}
  end

  @spec query_closed() :: t()
  def query_closed do
    %__MODULE__{statement: :closed}
  end

  @spec add_encoded_data(t(), bitstring()) :: t()
  def add_encoded_data(%__MODULE__{encoded_data: data} = result, element) do
    %__MODULE__{result | encoded_data: [element | data]}
  end

  @spec extract(t()) :: term() | EdgeDB.Set.t() | :ok

  def extract(%__MODULE__{cardinality: :one, set: set}) do
    if EdgeDB.Set.empty?(set) do
      raise EdgeDB.Protocol.Errors.NoDataError, "query didn't return any data"
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
      value = codec.decoder.(data)
      %__MODULE__{result | set: EdgeDB.Set.add(set, value)}
    end)
    |> Map.put(:encoded_data, nil)
    |> Map.put(:decoded?, true)
  end
end
