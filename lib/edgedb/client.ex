defmodule EdgeDB.Client do
  @moduledoc """
  Client is structure with stored configuration for executing EdgeQL queries
    and reference to pool or connection.

  After starting pool via `EdgeDB.start_link/1` or siblings an instance of a client
  for the pool will be implitly registered.

  In case you want to change the behaviour of your queries you'll use the `EdgeDB.Client`
  structure which is acceptable by all `EdgeDB` API and will be provided to you in callbacks
  in `EdgeDB.transaction/3`, `EdgeDB.subtransaction/2` and `EdgeDB.subtransaction!/2` functions.
  """

  defstruct [
    :conn,
    readonly: false,
    transaction_options: [],
    retry_options: [],
    state: %EdgeDB.State{}
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
          state: EdgeDB.State.t()
        }

  @typedoc """
  Options for EdgeDB transactions.

  These options are responsible for building the appropriate EdgeQL statement to start transactions and
    they correspond to [the EdgeQL transaction statement](https://www.edgedb.com/docs/reference/edgeql/tx_start#statement::start-transaction).

  Supported options:
    * `:isolation` - If `:serializable` is used, the built statement will use the `isolation serializable` mode.
      Currently only `:serializable` is supported by this driver and EdgeDB.
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

  @doc """
  Mark the client as read-only.

  See `EdgeDB.as_readonly/1` for more information.
  """
  @spec as_readonly(t()) :: t()
  def as_readonly(client) do
    client = to_client(client)
    %__MODULE__{client | readonly: true}
  end

  @doc """
  Configure the client so that futher transactions are executed with custom transaction options.

  See `EdgeDB.with_transaction_options/2` for more information.
  """
  @spec with_transaction_options(t(), list(transaction_option())) :: t()
  def with_transaction_options(client, options) do
    client = to_client(client)
    %__MODULE__{client | transaction_options: options}
  end

  @doc """
  Configure the client so that futher transactions retries are executed with custom retries options.

  See `EdgeDB.with_transaction_options/2` for more information.
  """
  @spec with_retry_options(t(), list(retry_option())) :: t()
  def with_retry_options(client, options) do
    client = to_client(client)
    %__MODULE__{client | retry_options: Keyword.merge(client.retry_options, options)}
  end

  @doc """
  Returns client with adjusted state.

  See `EdgeDB.with_state/2` for more information.
  """
  @spec with_state(t(), EdgeDB.State.t()) :: t()
  def with_state(client, state) do
    client = to_client(client)
    %__MODULE__{client | state: state}
  end

  @doc """
  Returns client with adjusted default module.

  See `EdgeDB.with_default_module/2` for more information.
  """
  @spec with_default_module(t(), String.t() | nil) :: t()
  def with_default_module(client, module \\ nil) do
    client = to_client(client)
    %__MODULE__{client | state: EdgeDB.State.with_default_module(client.state, module)}
  end

  @doc """
  Returns client with adjusted module aliases.

  See `EdgeDB.with_module_aliases/2` for more information.
  """
  @spec with_module_aliases(t(), %{String.t() => String.t()}) :: t()
  def with_module_aliases(client, aliases \\ %{}) do
    client = to_client(client)
    %__MODULE__{client | state: EdgeDB.State.with_module_aliases(client.state, aliases)}
  end

  @doc """
  Returns client without specified module aliases.

  See `EdgeDB.without_module_aliases/2` for more information.
  """
  @spec without_module_aliases(t(), list(String.t())) :: t()
  def without_module_aliases(client, aliases \\ []) do
    client = to_client(client)
    %__MODULE__{client | state: EdgeDB.State.without_module_aliases(client.state, aliases)}
  end

  @doc """
  Returns client with adjusted session config.

  See `EdgeDB.with_config/2` for more information.
  """
  @spec with_config(t(), %{atom() => term()}) :: t()
  def with_config(client, config \\ %{}) do
    client = to_client(client)
    %__MODULE__{client | state: EdgeDB.State.with_config(client.state, config)}
  end

  @doc """
  Returns client without specified session config.

  See `EdgeDB.without_config/2` for more information.
  """
  @spec without_config(t(), list(atom())) :: t()
  def without_config(client, config_keys \\ []) do
    client = to_client(client)
    %__MODULE__{client | state: EdgeDB.State.without_config(client.state, config_keys)}
  end

  @doc """
  Returns client with adjusted global values.

  See `EdgeDB.with_globals/2` for more information.
  """
  @spec with_globals(t(), %{String.t() => String.t()}) :: t()
  def with_globals(client, globals \\ %{}) do
    client = to_client(client)
    %__MODULE__{client | state: EdgeDB.State.with_globals(client.state, globals)}
  end

  @doc """
  Returns client without specified globals.

  See `EdgeDB.without_globals/2` for more information.
  """
  @spec without_globals(t(), list(String.t())) :: t()
  def without_globals(client, global_names \\ []) do
    client = to_client(client)
    %__MODULE__{client | state: EdgeDB.State.without_globals(client.state, global_names)}
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
