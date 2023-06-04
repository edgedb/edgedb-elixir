defmodule EdgeDB.Pool.State do
  @moduledoc false

  alias EdgeDB.Pool.Codel

  defstruct [
    :type,
    :queue,
    :codel,
    :ts,
    :current_concurrency,
    :suggested_concurrency,
    :max_concurrency,
    :conn_sup,
    :conn_mod,
    :conn_opts,
    :pool_idle_limit
  ]

  @type dbconnection_pool_type() :: :busy | :ready
  @type dbconnection_pool_ts() :: {integer(), integer()}
  @type dbconnection_pool_state() :: any()

  @type t() :: %__MODULE__{
          type: dbconnection_pool_type(),
          queue: :queue.queue(),
          codel: Codel.t(),
          ts: dbconnection_pool_ts(),
          current_concurrency: integer(),
          suggested_concurrency: integer() | nil,
          max_concurrency: integer() | nil,
          conn_sup: Supervisor.supervisor(),
          conn_mod: module(),
          conn_opts: Keyword.t(),
          pool_idle_limit: integer() | nil
        }

  @spec to_connection_pool_format(t()) :: dbconnection_pool_state()
  def to_connection_pool_format(%__MODULE__{} = state) do
    {state.type, state.queue, state.codel, state.ts}
  end

  @spec from_connection_pool_format(t(), dbconnection_pool_state()) :: t()
  def from_connection_pool_format(%__MODULE__{} = state, {type, queue, codel, ts}) do
    %__MODULE__{
      state
      | type: type,
        queue: queue,
        codel: codel,
        ts: ts
    }
  end
end
