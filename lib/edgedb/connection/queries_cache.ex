defmodule EdgeDB.Connection.QueriesCache do
  @moduledoc false

  alias EdgeDB.Protocol.Enums

  @type t() :: :ets.tab()

  @spec new() :: t()
  def new do
    :ets.new(:connection_queries_cache, [:set, :public, {:read_concurrency, true}])
  end

  @spec get(
          cache :: t(),
          statement :: String.t(),
          output_format :: Enums.output_format(),
          implicit_limit :: non_neg_integer(),
          inline_type_names :: boolean(),
          inline_type_ids :: boolean(),
          inline_object_ids :: boolean(),
          cardinality :: Enums.cardinality(),
          required :: boolean()
        ) :: EdgeDB.Query.t() | nil
  def get(
        cache,
        statement,
        output_format,
        implicit_limit,
        inline_type_names,
        inline_type_ids,
        inline_object_ids,
        cardinality,
        required
      ) do
    key = {
      statement,
      output_format,
      implicit_limit,
      inline_type_names,
      inline_type_ids,
      inline_object_ids,
      cardinality,
      required
    }

    case :ets.lookup(cache, key) do
      [{^key, query}] ->
        query

      [] ->
        nil
    end
  end

  @spec add(t(), EdgeDB.Query.t()) :: :ok
  def add(cache, %EdgeDB.Query{} = query) do
    key = query_to_key(query)
    :ets.insert(cache, {key, %EdgeDB.Query{query | cached: true}})
    :ok
  end

  @spec clear(t(), EdgeDB.Query.t()) :: :ok
  def clear(cache, %EdgeDB.Query{} = query) do
    key = query_to_key(query)
    :ets.delete(cache, key)
    :ok
  end

  defp query_to_key(query) do
    {
      query.statement,
      query.output_format,
      query.implicit_limit,
      query.inline_type_names,
      query.inline_type_ids,
      query.inline_object_ids,
      query.cardinality,
      query.required
    }
  end
end
