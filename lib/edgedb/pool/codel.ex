defmodule EdgeDB.Pool.Codel do
  @moduledoc false

  defstruct [
    :target,
    :interval,
    :delay,
    :slow,
    :next,
    :poll,
    :idle_interval,
    :idle_limit,
    :idle
  ]

  @type codel() :: %{
          target: integer(),
          interval: integer(),
          delay: integer(),
          slow: boolean(),
          next: integer(),
          poll: nil | reference(),
          idle_interval: integer(),
          idle_limit: integer(),
          idle: nil | reference()
        }

  @type t() :: %__MODULE__{
          target: integer(),
          interval: integer(),
          delay: integer(),
          slow: boolean(),
          next: integer(),
          poll: nil | reference(),
          idle_interval: integer(),
          idle_limit: integer(),
          idle: nil | reference()
        }
end
