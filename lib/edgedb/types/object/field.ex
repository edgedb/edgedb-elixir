defmodule EdgeDB.Object.Field do
  defstruct [
    :name,
    :value,
    :is_link,
    :is_link_property,
    :is_implicit
  ]

  @type t() :: %__MODULE__{
          name: String.t(),
          value: any(),
          is_link: boolean(),
          is_link_property: boolean(),
          is_implicit: boolean()
        }
end
