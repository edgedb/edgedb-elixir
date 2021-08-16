defmodule EdgeDB.Object.Field do
  defstruct [
    :name,
    :value,
    :link?,
    :link_property?,
    :implicit?
  ]

  @type t() :: %__MODULE__{
          name: String.t(),
          value: any(),
          link?: boolean(),
          link_property?: boolean(),
          implicit?: boolean()
        }
end
