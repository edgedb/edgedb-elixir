defmodule EdgeDB.Result do
  alias EdgeDB.Protocol.Enums

  defstruct [
    :cardinality,
    :required,
    set: [],
    statement: nil
  ]

  @type t() :: %__MODULE__{
          statement: String.t() | atom() | nil,
          required: boolean(),
          set: EdgeDB.Set.t() | list(binary()),
          cardinality: Enums.Cardinality.t()
        }

  @spec extract(t()) ::
          {:ok, EdgeDB.Set.t() | term() | :done}
          | {:error, Exception.t()}

  def extract(%__MODULE__{set: data}) when is_list(data) do
    {:error, EdgeDB.Error.interface_error("result hasn't been decoded yet")}
  end

  def extract(%__MODULE__{cardinality: :at_most_one, required: required, set: set}) do
    if EdgeDB.Set.empty?(set) and required do
      {:error, EdgeDB.Error.no_data_error("expected result, but query did not return any data")}
    else
      value =
        set
        |> Enum.take(1)
        |> List.first()

      {:ok, value}
    end
  end

  def extract(%__MODULE__{cardinality: :many, set: %EdgeDB.Set{} = set}) do
    {:ok, set}
  end

  def extract(%__MODULE__{cardinality: :no_result, required: true}) do
    {:error, EdgeDB.Error.interface_error("query does not return data")}
  end

  def extract(%__MODULE__{cardinality: :no_result}) do
    {:ok, :executed}
  end
end
