defmodule EdgeDB.ConfigMemory do
  defstruct [
    :bytes
  ]

  @opaque t() :: %__MODULE__{
            bytes: pos_integer()
          }
end
