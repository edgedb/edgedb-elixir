defmodule EdgeDB.Client do
  @moduledoc """
  Сlient is a structure that stores a custom configuration to execute EdgeQL queries
    and has a reference to a connection or pool of connections.

  After starting the pool via `EdgeDB.start_link/1` or siblings,
    the client instance for the pool will be implicitly registered.

  In case you want to change the behavior of your queries, you will use the `EdgeDB.Client`,
    which is acceptable by all `EdgeDB` API and will be provided to you in a callback
    in the `EdgeDB.transaction/3` function.
  """

  alias EdgeDB.Client.State

  defstruct [
    :conn,
    readonly: false,
    transaction_options: [],
    retry_options: [],
    state: %State{}
  ]

  @typedoc """
  Client is structure with stored configuration for executing EdgeQL queries
    and reference to pool or connection.

  Fields:

    * `:conn` - reference to connection or pool of connections.
    * `:readonly` - flag specifying that the client is read-only.
    * `:transaction_options` - options for EdgeDB transactions.
    * `:retry_options` - options for a retry rule for transactions retries.
    * `:state` - execution context that affects the execution of EdgeQL commands.
  """
  @type t() :: %__MODULE__{
          conn: DBConnection.conn(),
          readonly: boolean(),
          transaction_options: list(transaction_option()),
          retry_options: list(retry_option()),
          state: State.t()
        }

  @typedoc """
  Options for EdgeDB transactions.

  These options are responsible for building the appropriate EdgeQL statement to start transactions and
    they correspond to [the EdgeQL transaction statement](https://www.edgedb.com/docs/reference/edgeql/tx_start#statement::start-transaction).

  Supported options:

    * `:isolation` - If `:serializable` is used, the built statement will use the `isolation serializable` mode.
      Currently only `:serializable` is supported by this client and EdgeDB.
    * `:readonly` - if set to `true` then the built statement will use `read only` mode,
      otherwise `read write` will be used. The default is `false`.
    * `:deferrable` - if set to `true` then the built statement will use `deferrable` mode,
      otherwise `not deferrable` will be used. The default is `false`.
  """
  @type transaction_option() ::
          {:isolation, :serializable}
          | {:readonly, boolean()}
          | {:deferrable, boolean()}

  @typedoc """
  Options for a retry rule for transactions retries.

  See `EdgeDB.transaction/3`.

  Supported options:

    * `:attempts` - the number of attempts to retry the transaction in case of an error.
    * `:backoff` - function to determine the backoff before the next attempt to run a transaction.
  """
  @type retry_rule() ::
          {:attempts, pos_integer()}
          | {:backoff, (pos_integer() -> timeout())}

  @typedoc """
  Options for transactions and read-only queries retries.

  See `EdgeDB.transaction/3`.

  Supported options:

    * `:transaction_conflict` - the rule that will be used in case of any transaction conflict.
    * `:network_error` - rule which will be used when any network error occurs on the client.
  """
  @type retry_option() ::
          {:transaction_conflict, retry_rule()}
          | {:network_error, retry_rule()}

  @doc false
  @spec as_readonly(t()) :: t()
  def as_readonly(client) do
    client = to_client(client)
    %__MODULE__{client | readonly: true}
  end

  @doc false
  @spec with_transaction_options(t(), list(transaction_option())) :: t()
  def with_transaction_options(client, options) do
    client = to_client(client)
    %__MODULE__{client | transaction_options: options}
  end

  @doc false
  @spec with_retry_options(t(), list(retry_option())) :: t()
  def with_retry_options(client, options) do
    client = to_client(client)
    %__MODULE__{client | retry_options: Keyword.merge(client.retry_options, options)}
  end

  @doc false
  @spec with_state(t(), State.t()) :: t()
  def with_state(client, state) do
    client = to_client(client)
    %__MODULE__{client | state: state}
  end

  @doc false
  @spec with_default_module(t(), String.t() | nil) :: t()
  def with_default_module(client, module \\ nil) do
    client = to_client(client)
    %__MODULE__{client | state: State.with_default_module(client.state, module)}
  end

  @doc false
  @spec with_module_aliases(t(), %{String.t() => String.t()}) :: t()
  def with_module_aliases(client, aliases \\ %{}) do
    client = to_client(client)
    %__MODULE__{client | state: State.with_module_aliases(client.state, aliases)}
  end

  @doc false
  @spec without_module_aliases(t(), list(String.t())) :: t()
  def without_module_aliases(client, aliases \\ []) do
    client = to_client(client)
    %__MODULE__{client | state: State.without_module_aliases(client.state, aliases)}
  end

  @doc false
  @spec with_config(t(), %{atom() => term()}) :: t()
  def with_config(client, config \\ %{}) do
    client = to_client(client)
    %__MODULE__{client | state: State.with_config(client.state, config)}
  end

  @doc false
  @spec without_config(t(), list(atom())) :: t()
  def without_config(client, config_keys \\ []) do
    client = to_client(client)
    %__MODULE__{client | state: State.without_config(client.state, config_keys)}
  end

  @doc false
  @spec with_globals(t(), %{String.t() => String.t()}) :: t()
  def with_globals(client, globals \\ %{}) do
    client = to_client(client)
    %__MODULE__{client | state: State.with_globals(client.state, globals)}
  end

  @doc false
  @spec without_globals(t(), list(String.t())) :: t()
  def without_globals(client, global_names \\ []) do
    client = to_client(client)
    %__MODULE__{client | state: State.without_globals(client.state, global_names)}
  end

  @doc false
  @spec to_conn(t() | DBConnection.conn()) :: t()

  def to_conn(%__MODULE__{conn: conn}) do
    conn
  end

  def to_conn(conn) do
    conn
  end

  @doc false
  @spec to_options(t()) :: Keyword.t()

  def to_options(%__MODULE__{} = client) do
    capabilities =
      if client.readonly do
        [:readonly]
      else
        []
      end

    [
      capabilities: capabilities,
      transaction_options: client.transaction_options,
      retry_options: client.retry_options,
      edgeql_state: client.state
    ]
  end

  defp to_client(%__MODULE__{} = client) do
    client
  end

  defp to_client(conn) do
    %__MODULE__{conn: conn}
  end
end
