defmodule EdgeDB.Result do
  defstruct [
    :statement,
    :cardinality,
    :set,
    encoded_data: [],
    decoded?: false
  ]

  def new(cardinality) do
    %__MODULE__{cardinality: cardinality, set: EdgeDB.Set._new()}
  end

  def query_closed do
    %__MODULE__{statement: :closed}
  end

  def add_encoded_data(%__MODULE__{encoded_data: data} = result, element) do
    %__MODULE__{result | encoded_data: [element | data]}
  end

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

  def decode(%__MODULE__{} = result, codec) do
    result.encoded_data
    |> Enum.reverse()
    |> Enum.reduce(result, fn data, %__MODULE__{set: set} = result ->
      value = codec.decoder.(data)
      %__MODULE__{result | set: EdgeDB.Set._add(set, value)}
    end)
    |> Map.put(:encoded_data, nil)
    |> Map.put(:decoded?, true)
  end
end
