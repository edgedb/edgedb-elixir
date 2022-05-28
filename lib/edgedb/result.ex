defmodule EdgeDB.Result do
  @moduledoc """
  A structure that contains information related to the query result.

  It's mostly used in driver internally, but user can retrive it along with `EdgeDB.Query` struct
    from succeed query execution using `:raw` option for `EdgeDB.query*/4` functions. See `t:EdgeDB.query_option/0`.
  """

  alias EdgeDB.Protocol.Enums

  defstruct [
    :cardinality,
    :required,
    set: [],
    statement: nil
  ]

  @typedoc """
  A structure that contains information related to the query result.

  Fields:

    * `:statement` - EdgeQL statement that was executed.
    * `:required` - flag specifying that the result should not be empty.
    * `:set` - query result.
    * `:cardinality` - the expected number of elements in the returned set as a result of the query.
  """
  @type t() :: %__MODULE__{
          statement: String.t() | nil,
          required: boolean(),
          set: EdgeDB.Set.t() | list(binary()),
          cardinality: Enums.cardinality()
        }

  @doc """
  Process the result and extract the data.
  """
  @spec extract(t()) ::
          {:ok, EdgeDB.Set.t() | term() | :done}
          | {:error, Exception.t()}

  def extract(%__MODULE__{set: data}) when is_list(data) do
    {:error, EdgeDB.InterfaceError.new("result hasn't been decoded yet")}
  end

  def extract(%__MODULE__{cardinality: :at_most_one, required: required, set: set}) do
    if EdgeDB.Set.empty?(set) and required do
      {:error, EdgeDB.NoDataError.new("expected result, but query did not return any data")}
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
    {:error, EdgeDB.InterfaceError.new("query does not return data")}
  end

  def extract(%__MODULE__{cardinality: :no_result}) do
    {:ok, :executed}
  end
end
