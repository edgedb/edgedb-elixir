defmodule EdgeDB.Protocol.Messages do
  @moduledoc false

  alias EdgeDB.Protocol.{
    Codec,
    Enums,
    Types
  }

  defmodule Client do
    @moduledoc false

    defmodule AuthenticationSASLInitialResponse do
      @moduledoc false

      defstruct [
        :method,
        :sasl_data
      ]

      @type t() :: %__MODULE__{
              method: String.t(),
              sasl_data: binary()
            }
    end

    defmodule AuthenticationSASLResponse do
      @moduledoc false

      defstruct [
        :sasl_data
      ]

      @type t() :: %__MODULE__{
              sasl_data: binary()
            }
    end

    defmodule ClientHandshake do
      @moduledoc false

      defstruct [
        :major_ver,
        :minor_ver,
        :params,
        :extensions
      ]

      @type t() :: %__MODULE__{
              major_ver: non_neg_integer(),
              minor_ver: non_neg_integer(),
              params: list(Types.ConnectionParam.t()),
              extensions: list(Types.ProtocolExtension.t())
            }
    end

    defmodule DescribeStatement do
      @moduledoc false

      defstruct [
        :headers,
        :aspect,
        :statement_name
      ]

      @type t() :: %__MODULE__{
              headers: map(),
              aspect: Enums.describe_aspect(),
              statement_name: binary()
            }
    end

    defmodule ExecuteScript do
      @moduledoc false

      defstruct [
        :headers,
        :script
      ]

      @type headers() :: %{
              optional(:allow_capabilities) => Enums.capabilities()
            }

      @type t() :: %__MODULE__{
              headers: headers(),
              script: String.t()
            }
    end

    defmodule Execute do
      @moduledoc false

      defstruct [
        :headers,
        :statement_name,
        :arguments
      ]

      @type headers() :: %{
              optional(:allow_capabilities) => Enums.capabilities()
            }

      @type t() :: %__MODULE__{
              headers: headers(),
              statement_name: binary(),
              arguments: iodata()
            }
    end

    defmodule Flush do
      @moduledoc false

      defstruct []

      @type t() :: %__MODULE__{}
    end

    defmodule OptimisticExecute do
      @moduledoc false

      defstruct [
        :headers,
        :io_format,
        :expected_cardinality,
        :command_text,
        :input_typedesc_id,
        :output_typedesc_id,
        :arguments
      ]

      @type headers() :: %{
              optional(:implicit_limit) => String.t(),
              optional(:implicit_typenames) => String.t(),
              optional(:implicit_typeids) => String.t(),
              optional(:allow_capabilities) => Enums.capabilities(),
              optional(:explicit_objectids) => String.t()
            }

      @type t() :: %__MODULE__{
              headers: headers(),
              io_format: Enums.io_format(),
              expected_cardinality: Enums.cardinality(),
              command_text: String.t(),
              input_typedesc_id: Codec.id(),
              output_typedesc_id: Codec.id(),
              arguments: iodata()
            }
    end

    defmodule Prepare do
      @moduledoc false

      defstruct [
        :headers,
        :io_format,
        :expected_cardinality,
        :statement_name,
        :command
      ]

      @type headers() :: %{
              optional(:implicit_limit) => String.t(),
              optional(:implicit_typenames) => String.t(),
              optional(:implicit_typeids) => String.t(),
              optional(:allow_capabilities) => Enums.capabilities(),
              optional(:explicit_objectids) => String.t()
            }

      @type t() :: %__MODULE__{
              headers: headers(),
              io_format: Enums.io_format(),
              expected_cardinality: Enums.cardinality(),
              statement_name: binary(),
              command: String.t()
            }
    end

    defmodule Sync do
      @moduledoc false

      defstruct []

      @type t() :: %__MODULE__{}
    end

    defmodule Terminate do
      @moduledoc false

      defstruct []

      @type t() :: %__MODULE__{}
    end
  end

  defmodule Server do
    @moduledoc false

    defmodule AuthenticationOK do
      @moduledoc false

      defstruct [
        :auth_status
      ]

      @type t() :: %__MODULE__{
              auth_status: non_neg_integer()
            }
    end

    defmodule AuthenticationSASLContinue do
      @moduledoc false

      defstruct [
        :auth_status,
        :sasl_data
      ]

      @type t() :: %__MODULE__{
              auth_status: non_neg_integer(),
              sasl_data: binary()
            }
    end

    defmodule AuthenticationSASLFinal do
      @moduledoc false

      defstruct [
        :auth_status,
        :sasl_data
      ]

      @type t() :: %__MODULE__{
              auth_status: non_neg_integer(),
              sasl_data: binary()
            }
    end

    defmodule AuthenticationSASL do
      @moduledoc false

      defstruct [
        :auth_status,
        :methods
      ]

      @type t() :: %__MODULE__{
              auth_status: non_neg_integer(),
              methods: list(String.t())
            }
    end

    defmodule CommandComplete do
      @moduledoc false

      defstruct [
        :headers,
        :status
      ]

      @type headers() :: %{
              optional(:capabilities) => Enums.capabilities()
            }

      @type t() :: %__MODULE__{
              headers: headers(),
              status: String.t()
            }
    end

    defmodule CommandDataDescription do
      @moduledoc false

      defstruct [
        :headers,
        :result_cardinality,
        :input_typedesc_id,
        :input_typedesc,
        :output_typedesc_id,
        :output_typedesc
      ]

      @type t() :: %__MODULE__{
              headers: map(),
              result_cardinality: Enums.cardinality(),
              input_typedesc_id: Codec.id(),
              input_typedesc: binary(),
              output_typedesc_id: Codec.id(),
              output_typedesc: binary()
            }
    end

    defmodule Data do
      @moduledoc false

      defstruct [
        :data
      ]

      @type t() :: %__MODULE__{
              data: binary()
            }
    end

    defmodule ErrorResponse do
      @moduledoc false

      defstruct [
        :severity,
        :error_code,
        :message,
        :attributes
      ]

      @type attributes() :: %{
              optional(:hint) => String.t(),
              optional(:details) => String.t(),
              optional(:server_traceback) => String.t(),
              optional(:position_start) => String.t(),
              optional(:position_end) => String.t(),
              optional(:line_start) => String.t(),
              optional(:column_start) => String.t(),
              optional(:utf16_column_start) => String.t(),
              optional(:line_end) => String.t(),
              optional(:column_end) => String.t(),
              optional(:utf16_column_end) => String.t(),
              optional(:character_start) => String.t(),
              optional(:character_end) => String.t()
            }

      @type t() :: %__MODULE__{
              severity: Enums.error_severity(),
              error_code: non_neg_integer(),
              message: String.t(),
              attributes: attributes()
            }
    end

    defmodule LogMessage do
      @moduledoc false

      defstruct [
        :severity,
        :code,
        :text,
        :attributes
      ]

      @type t() :: %__MODULE__{
              severity: Enums.message_severity(),
              code: non_neg_integer(),
              text: String.t(),
              attributes: map()
            }
    end

    defmodule ParameterStatus do
      @moduledoc false

      defstruct [
        :name,
        :value
      ]

      @type t() :: %__MODULE__{
              name: binary(),
              value: binary()
            }
    end

    defmodule PrepareComplete do
      @moduledoc false

      defstruct [
        :headers,
        :cardinality,
        :input_typedesc_id,
        :output_typedesc_id
      ]

      @type t() :: %__MODULE__{
              headers: map(),
              cardinality: Enums.cardinality(),
              input_typedesc_id: Codec.id(),
              output_typedesc_id: Codec.t()
            }
    end

    defmodule ReadyForCommand do
      @moduledoc false

      defstruct [
        :headers,
        :transaction_state
      ]

      @type t() :: %__MODULE__{
              headers: map(),
              transaction_state: Enums.transaction_state()
            }
    end

    defmodule ServerHandshake do
      @moduledoc false

      defstruct [
        :major_ver,
        :minor_ver,
        :extensions
      ]

      @type t() :: %__MODULE__{
              major_ver: non_neg_integer(),
              minor_ver: non_neg_integer(),
              extensions: list(Types.ProtocolExtension.t())
            }
    end

    defmodule ServerKeyData do
      @moduledoc false

      defstruct [
        :data
      ]

      @type t() :: %__MODULE__{
              data: binary()
            }
    end
  end
end
