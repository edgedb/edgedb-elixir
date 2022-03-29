defmodule EdgeDB.Protocol.Types do
  @moduledoc false

  alias EdgeDB.Protocol.Enums

  defmodule ArrayElement do
    @moduledoc false

    defstruct [
      :data
    ]

    @type t() :: %__MODULE__{
            data: binary()
          }
  end

  defmodule ConnectionParam do
    @moduledoc false

    defstruct [
      :name,
      :value
    ]

    @type t() :: %__MODULE__{
            name: String.t(),
            value: String.t()
          }
  end

  defmodule DataElement do
    @moduledoc false

    defstruct [
      :data
    ]

    @type t() :: %__MODULE__{
            data: binary()
          }
  end

  defmodule Dimension do
    @moduledoc false

    defstruct [
      :upper,
      lower: 1
    ]

    @type t() :: %__MODULE__{
            upper: integer(),
            lower: integer()
          }
  end

  defmodule Envelope do
    @moduledoc false

    defstruct [
      :elements
    ]

    @type t() :: %__MODULE__{
            elements: ArrayElement.t()
          }
  end

  defmodule Header do
    @moduledoc false

    defstruct [
      :code,
      :value
    ]

    @type t() :: %__MODULE__{
            code: pos_integer(),
            value: binary()
          }
  end

  defmodule TupleElement do
    @moduledoc false

    defstruct [
      :name,
      :type_pos
    ]

    @type t() :: %__MODULE__{
            name: String.t(),
            type_pos: non_neg_integer()
          }
  end

  defmodule ProtocolExtension do
    @moduledoc false

    defstruct [
      :name,
      :headers
    ]

    @type t() :: %__MODULE__{
            name: String.t(),
            headers: list(Header.t())
          }
  end

  defmodule ShapeElement do
    @moduledoc false

    defstruct [
      :flags,
      :cardinality,
      :name,
      :type_pos
    ]

    @type t() :: %__MODULE__{
            flags: pos_integer(),
            cardinality: Enums.cardinality(),
            name: String.t(),
            type_pos: non_neg_integer()
          }
  end

  defmodule Element do
    @moduledoc false

    defstruct [
      :data
    ]

    @type t() :: %__MODULE__{
            data: binary()
          }
  end

  defmodule ParameterStatus do
    @moduledoc false

    defmodule SystemConfig do
      @moduledoc false

      defstruct [
        :typedesc_id,
        :typedesc,
        :data
      ]

      @type t() :: %__MODULE__{
              typedesc_id: binary(),
              typedesc: binary(),
              data: DataElement.t()
            }
    end
  end
end
