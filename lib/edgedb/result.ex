defmodule EdgeDB.Result do
  alias EdgeDB.Protocol.{
    Enums,
    Error
  }

  defstruct [
    :cardinality,
    set: [],
    statement: nil
  ]

  @type t() :: %__MODULE__{
          statement: String.t() | atom() | nil,
          set: EdgeDB.Set.t() | list(binary()),
          cardinality: Enums.Cardinality.t()
        }

  @spec extract(t()) :: EdgeDB.Set.t() | term() | :ok

  def extract(%__MODULE__{set: data}) when is_list(data) do
    raise Error.interface_error("result hasn't been decoded yet")
  end

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
end
