defmodule EdgeDB.Result do
  @moduledoc false

  alias EdgeDB.Protocol.Enums

  defstruct [
    :cardinality,
    :required,
    set: [],
    statement: nil
  ]

  @type t() :: %__MODULE__{
          statement: String.t() | nil,
          required: boolean(),
          set: EdgeDB.Set.t() | list(binary()),
          cardinality: Enums.cardinality()
        }

  @spec extract(t(), Keyword.t() | nil) ::
          {:ok, EdgeDB.Set.t() | term() | :done}
          | {:error, Exception.t()}

  def extract(result, transform_result \\ nil)

  def extract(%__MODULE__{set: data}, _transform_result) when is_list(data) do
    {:error, EdgeDB.InterfaceError.new("result hasn't been decoded yet")}
  end

  def extract(
        %__MODULE__{
          cardinality: :at_most_one,
          required: required,
          set: set
        },
        transform_result
      ) do
    if EdgeDB.Set.empty?(set) and required do
      {:error, EdgeDB.NoDataError.new("expected result, but query did not return any data")}
    else
      set
      |> Enum.take(1)
      |> List.first()
      |> maybe_transform_result(transform_result)
    end
  end

  def extract(%__MODULE__{cardinality: :many, set: %EdgeDB.Set{} = set}, transform_result) do
    maybe_transform_result(set, transform_result)
  end

  def extract(%__MODULE__{cardinality: :no_result, required: true}, _transform_result) do
    {:error, EdgeDB.InterfaceError.new("query does not return data")}
  end

  def extract(%__MODULE__{cardinality: :no_result}, _transform_result) do
    {:ok, :executed}
  end

  defp maybe_transform_result(value, nil) do
    {:ok, value}
  end

  defp maybe_transform_result(value, opts) do
    schema =
      opts
      |> Keyword.get(:schema, [])
      |> stringify_schema()

    do_transform(value, schema)
  end

  defp do_transform(%EdgeDB.Set{} = set, schema) do
    transformation_result =
      Enum.reduce_while(set, {:ok, []}, fn element, {:ok, list} ->
        case do_transform(element, schema) do
          {:ok, element} ->
            {:cont, {:ok, [element | list]}}

          {:error, _reason} = error ->
            {:halt, error}
        end
      end)

    with {:ok, list} <- transformation_result do
      {:ok, Enum.reverse(list)}
    end
  end

  defp do_transform(%EdgeDB.Object{} = object, schema) do
    object.__fields__
    |> Enum.reject(fn {name, field} ->
      not Map.has_key?(schema, name) or field.is_implicit
    end)
    |> Enum.reduce_while({:ok, %{}}, fn {name, field}, {:ok, map} ->
      case do_transform(field.value, schema[name]) do
        {:ok, value} ->
          {:cont, {:ok, Map.put(map, String.to_existing_atom(name), value)}}

        {:error, _reason} = error ->
          {:halt, error}
      end
    end)
  end

  defp do_transform(%EdgeDB.NamedTuple{} = nt, schema) do
    index_map =
      Enum.into(nt.__fields_ordering__, %{}, fn {index, name} ->
        {index, nt.__items__[name]}
      end)

    keys_map =
      Enum.reduce(nt.__items__, %{}, fn {key, value}, acc ->
        if Map.has_key?(schema, key) do
          Map.put(acc, key, value)
        else
          acc
        end
      end)

    index_map
    |> Map.merge(keys_map)
    |> Enum.reduce_while({:ok, %{}}, fn {key, value}, {:ok, map} ->
      schema =
        if is_integer(key) do
          schema[nt.__fields_ordering__[key]]
        else
          schema[key]
        end

      case do_transform(value, schema) do
        {:ok, value} when is_binary(key) ->
          {:cont, {:ok, Map.put(map, String.to_existing_atom(key), value)}}

        {:ok, value} when is_integer(key) ->
          {:cont, {:ok, Map.put(map, key, value)}}

        {:error, _reason} = error ->
          {:halt, error}
      end
    end)
  end

  defp do_transform(array, schema) when is_list(array) do
    transformation_result =
      Enum.reduce_while(array, {:ok, []}, fn value, {:ok, list} ->
        case do_transform(value, schema) do
          {:ok, value} ->
            {:cont, {:ok, [value | list]}}

          {:error, _reason} = error ->
            {:halt, error}
        end
      end)

    with {:ok, list} <- transformation_result do
      {:ok, Enum.reverse(list)}
    end
  end

  defp do_transform(tuple, schema) when is_tuple(tuple) do
    transformation_result =
      tuple
      |> Tuple.to_list()
      |> Enum.reduce_while({:ok, []}, fn value, {:ok, list} ->
        case do_transform(value, schema) do
          {:ok, value} ->
            {:cont, {:ok, [value | list]}}

          {:error, _reason} = error ->
            {:halt, error}
        end
      end)

    with {:ok, list} <- transformation_result do
      tuple =
        list
        |> Enum.reverse()
        |> List.to_tuple()

      {:ok, tuple}
    end
  end

  defp do_transform(value, _schema) do
    {:ok, value}
  end

  defp stringify_schema(schema) do
    Enum.into(schema, %{}, fn
      {name, schema} ->
        {to_string(name), stringify_schema(schema)}

      name ->
        {to_string(name), nil}
    end)
  end
end
