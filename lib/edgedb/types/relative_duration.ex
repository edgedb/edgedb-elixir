defmodule EdgeDB.RelativeDuration do
  defstruct months: 0,
            days: 0,
            microseconds: 0

  @type t() :: %__MODULE__{
          months: pos_integer(),
          days: pos_integer(),
          microseconds: pos_integer()
        }
end
