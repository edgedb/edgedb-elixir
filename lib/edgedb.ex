defmodule EdgeDB do
  @moduledoc """
  EdgeDB client for Elixir.

  `EdgeDB` module provides an API to run a connection pool, query EdgeDB, perform transactions
    and their rollback.

  A simple example of how to use it:

  ```iex
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> EdgeDB.query!(client, "\"\"
  ...(2)>   select Person{
  ...(2)>     first_name,
  ...(2)>     middle_name,
  ...(2)>     last_name
  ...(2)>   } filter .last_name = <str>$last_name;
  ...(2)> \"\"", last_name: "Radcliffe")
  #EdgeDB.Set<{#EdgeDB.Object<first_name := "Daniel", middle_name := "Jacob", last_name := "Radcliffe">}>
  ```
  """

  alias EdgeDB.Connection.Config
  alias EdgeDB.Protocol.Enums

  @typedoc """
  Connection pool process name, pid or the separate structure
    that allows adjusted configuration for queries executed on the connection.

  See `EdgeDB.as_readonly/1`, `EdgeDB.with_retry_options/2`, `EdgeDB.with_transaction_options/2`
    for more information.
  """
  @type client() :: DBConnection.conn() | EdgeDB.Client.t()

  @typedoc """
  Security modes for TLS connection to EdgeDB server.

  For more information, see [the EdgeDB documentation on connection parameters](https://www.edgedb.com/docs/reference/connection#ref-reference-connection-granular).

  Supported options:

    * `:insecure` - trust a self-signed or user-signed TLS certificate, which is useful for local development.
    * `:no_host_verification` - verify the TLS certificate, but not the host name.
    * `:strict` - verify both the TLS certificate and the hostname.
    * `:default` - the same as `:strict`.
  """
  @type tls_security() :: :insecure | :no_host_verification | :strict | :default

  # NOTE: :command_timeout and :server_settings
  # options added only for compatability with other clients and aren't used right now
  @typedoc """
  Parameters for connecting to an EdgeDB instance and configuring the connection itself.

  EdgeDB clients allow a very flexible way to define how to connect to an instance.
    For more information, see [the EdgeDB documentation on connection parameters](https://www.edgedb.com/docs/reference/connection#ref-reference-connection-granular).

  Supported options:

    * `:dsn` - DSN that defines the primary information that can be used to connect to the instance.
    * `:credentials` - a JSON string containing the instance parameters to connect.
    * `:credentials_file` - the path to the instance credentials file containing the instance parameters to connect to.
    * `:host` - the host name of the instance to connect to.
    * `:port` - the port number of the instance to connect to.
    * `:database` - the name of the database to connect to.
    * `:user` - the user name to connect to.
    * `:password` - the user password to connect.
    * `:secret_key` - the secret key to be used for authentication.
    * `:tls_ca` - TLS certificate to be used when connecting to the instance.
    * `:tls_ca_path` - the path to the TLS certificate to be used when connecting to the instance.
    * `:tls_security` - security mode for the TLS connection. See `t:EdgeDB.tls_security/0`.
    * `:timeout` - timeout for TCP operations with the database, such as connecting to it, sending or receiving data.
    * `:command_timeout` - *not in use right now and added for compatibility with other clients*.
    * `:server_settings` - *not in use right now and added for compatibility with other clients*.
    * `:tcp` - options for the TCP connection.
    * `:ssl` - options for TLS connection.
    * `:transaction` - options for EdgeDB transactions, which correspond to
      [the EdgeQL transaction statement](https://www.edgedb.com/docs/reference/edgeql/tx_start#statement::start-transaction).
      See `t:EdgeDB.Client.transaction_option/0`.
    * `:retry` - options to retry transactions in case of errors. See `t:EdgeDB.Client.retry_option/0`.
    * `:codecs` - list of custom codecs for EdgeDB scalars.
    * `:connection` - module that implements the `DBConnection` behavior for EdgeDB.
      For tests, it's possible to use `EdgeDB.Sandbox` to support automatic rollback after tests are done.
    * `:max_concurrency` - maximum number of pool connections, despite what EdgeDB recommends.
    * `:client_state` - an `EdgeDB.Client.State` struct that will be used in queries by default.
  """
  @type connect_option() ::
          {:dsn, String.t()}
          | {:credentials, String.t()}
          | {:credentials_file, Path.t()}
          | {:host, String.t()}
          | {:port, :inet.port_number()}
          | {:database, String.t()}
          | {:user, String.t()}
          | {:password, String.t()}
          | {:tls_ca, String.t()}
          | {:tls_ca_file, Path.t()}
          | {:tls_security, tls_security()}
          | {:timeout, timeout()}
          | {:command_timeout, timeout()}
          | {:server_settings, map()}
          | {:tcp, list(:gen_tcp.option())}
          | {:ssl, list(:ssl.tls_client_option())}
          | {:transaction, list(EdgeDB.Client.transaction_option())}
          | {:retry, list(EdgeDB.Client.retry_option())}
          | {:codecs, list(module())}
          | {:connection, module()}
          | {:max_concurrency, pos_integer()}
          | {:client_state, EdgeDB.Client.State.t()}

  @typedoc """
  Options for `EdgeDB.start_link/1`.

  See `t:EdgeDB.connect_option/0` and `t:DBConnection.start_option/0`.
  """
  @type start_option() ::
          connect_option()
          | DBConnection.start_option()

  @typedoc """
  Options for `EdgeDB.query*/4` functions.

  These options can be used with the following functions:

    * `EdgeDB.query/4`
    * `EdgeDB.query!/4`
    * `EdgeDB.query_single/4`
    * `EdgeDB.query_single!/4`
    * `EdgeDB.query_required_single/4`
    * `EdgeDB.query_required_single!/4`
    * `EdgeDB.query_json/4`
    * `EdgeDB.query_json!/4`
    * `EdgeDB.query_single_json/4`
    * `EdgeDB.query_single_json!/4`
    * `EdgeDB.query_required_single_json/4`
    * `EdgeDB.query_required_single_json!/4`

  Supported options:

    * `:cardinality` - expected number of items in set.
    * `:output_format` - preferred format of query result.
    * `:retry` - options for read-only queries retries.
    * other - check `t:DBConnection.option/0`.
  """
  @type query_option() ::
          {:cardinality, Enums.cardinality()}
          | {:output_format, Enums.output_format()}
          | {:retry, list(EdgeDB.Client.retry_option())}
          | {:script, boolean()}
          | DBConnection.option()

  @typedoc """
  Options for `EdgeDB.transaction/3`.

  See `t:EdgeDB.Client.transaction_option/0`, `t:EdgeDB.Client.retry_option/0`
    and `t:DBConnection.option/0`.
  """
  @type transaction_option() ::
          EdgeDB.Client.transaction_option()
          | {:retry, list(EdgeDB.Client.retry_option())}
          | DBConnection.option()

  @typedoc """
  Options for `EdgeDB.rollback/2`.

  Supported options:

    * `:reason` - the reason for the rollback. Will be returned from `EdgeDB.transaction/3`
      as a `{:error, reason}` tuple in case block execution is interrupted.
  """
  @type rollback_option() ::
          {:reason, term()}

  @typedoc """
  The result that will be returned if the `EdgeDB.query*/4` function succeeds.
  """
  @type result() :: EdgeDB.Set.t() | term()

  @doc """
  Creates a pool of EdgeDB connections linked to the current process.

  If the first argument is a string, it will be assumed to be the DSN or instance name
    and passed as `[dsn: dsn]` keyword list to connect.

  ```iex
  iex(1)> {:ok, _client} = EdgeDB.start_link("edgedb://edgedb:edgedb@localhost:5656/edgedb")

  ```

  Otherwise, if the first argument is a list, it will be used as is to connect.
    See `t:EdgeDB.start_option/0` for supported connection options.

  ```iex
  iex(1)> {:ok, _client} = EdgeDB.start_link(instance: "edgedb_elixir")

  ```
  """
  def start_link(opts \\ [])

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(dsn) when is_binary(dsn) do
    opts = prepare_opts(dsn: dsn)

    opts
    |> Keyword.get(:connection, EdgeDB.Connection)
    |> DBConnection.start_link(opts)
    |> register_client(opts)
  end

  @spec start_link(list(start_option())) :: GenServer.on_start()
  def start_link(opts) do
    opts = prepare_opts(opts)

    opts
    |> Keyword.get(:connection, EdgeDB.Connection)
    |> DBConnection.start_link(opts)
    |> register_client(opts)
  end

  @doc """
  Creates a pool of EdgeDB connections linked to the current process.

  The first argument is the string which will be assumed as the DSN and passed as
    `[dsn: dsn]` keyword list along with other options to connect.
    See `t:EdgeDB.start_option/0` for supported connection options.

  ```iex
  iex(1)> {:ok, _client} = EdgeDB.start_link("edgedb://edgedb:edgedb@localhost:5656/edgedb", tls_security: :insecure)

  ```
  """
  @spec start_link(String.t(), list(start_option())) :: GenServer.on_start()
  def start_link(dsn, opts) do
    opts =
      [dsn: dsn]
      |> Keyword.merge(opts)
      |> prepare_opts()

    opts
    |> Keyword.get(:connection, EdgeDB.Connection)
    |> DBConnection.start_link(opts)
    |> register_client(opts)
  end

  @doc """
  Creates a child specification for the supervisor to start the EdgeDB pool.

  See `t:EdgeDB.start_option/0` for supported connection options.
  """
  @spec child_spec(list(start_option())) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    opts = prepare_opts(opts)

    %{
      id: EdgeDB,
      start: {EdgeDB, :start_link, [opts]}
    }
  end

  @doc """
  Execute the query on the client and return the results as a `{:ok, set}` tuple
    if successful, where `set` is `EdgeDB.Set`.

  ```iex
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> {:ok, %EdgeDB.Set{} = set} = EdgeDB.query(client, "select 42")
  iex(3)> set
  #EdgeDB.Set<{42}>
  ```

  If an error occurs, it will be returned as a `{:error, exception}` tuple
    where `exception` is `EdgeDB.Error`.

  ```iex
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> {:error, %EdgeDB.Error{} = error} = EdgeDB.query(client, "select UndefinedType")
  iex(3)> raise error
  ** (EdgeDB.Error) InvalidReferenceError: object type or alias 'default::UndefinedType' does not exist
    ┌─ query:1:8
    │
  1 │   select UndefinedType
    │          ^^^^^^^^^^^^^ error
  ```

  If a query has arguments, they can be passed as a list for a query with positional arguments
    or as a list of keywords for a query with named arguments.

  ```iex
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> {:ok, %EdgeDB.Set{} = set} = EdgeDB.query(client, "select <int64>$0", [42])
  iex(3)> set
  #EdgeDB.Set<{42}>
  ```

  ```iex
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> {:ok, %EdgeDB.Set{} = set} = EdgeDB.query(client, "select <int64>$arg", arg: 42)
  iex(3)> set
  #EdgeDB.Set<{42}>
  ```

  ### Automatic retries of read-only queries

  If the client is able to recognize the query as a read-only query
    (i.e. the query does not change the data in the database using `delete`, `insert` or other statements),
    then the client will try to repeat the query automatically (as long as the query is not executed in a transaction,
    because then [retrying transactions](`EdgeDB.transaction/3`) are used).

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query(client(), String.t(), list() | Keyword.t(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query(client, statement, params \\ [], opts \\ []) do
    q = %EdgeDB.Query{
      statement: statement,
      cardinality: Keyword.get(opts, :cardinality, :many),
      output_format: Keyword.get(opts, :output_format, :binary),
      required: Keyword.get(opts, :required, false),
      is_script: Keyword.get(opts, :script, false),
      params: params
    }

    parse_execute_query(client, q, q.params, opts)
  end

  @doc """
  Execute the query on the client and return the results as `EdgeDB.Set`.
    If an error occurs while executing the query, it will be raised as
    as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query!(client(), String.t(), list(), list(query_option())) :: result()
  def query!(client, statement, params \\ [], opts \\ []) do
    client
    |> query(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute the query on the client and return an optional singleton-returning
    result as a `{:ok, result}` tuple.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query_single(client(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_single(client, statement, params \\ [], opts \\ []) do
    query(client, statement, params, Keyword.merge(opts, cardinality: :at_most_one))
  end

  @doc """
  Execute the query on the client and return an optional singleton-returning result.
    If an error occurs while executing the query, it will be raised
    as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query_single!(client(), String.t(), list(), list(query_option())) :: result()
  def query_single!(client, statement, params \\ [], opts \\ []) do
    client
    |> query_single(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute the query on the client and return a singleton-returning result
    as a `{:ok, result}` tuple.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query_required_single(client(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_required_single(client, statement, params \\ [], opts \\ []) do
    query_single(client, statement, params, Keyword.merge(opts, required: true))
  end

  @doc """
  Execute the query on the client and return a singleton-returning result.
    If an error occurs while executing the query, it will be raised
    as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query_required_single!(client(), String.t(), list(), list(query_option())) :: result()
  def query_required_single!(client, statement, params \\ [], opts \\ []) do
    client
    |> query_required_single(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute the query on the client and return the results as a `{:ok, json}` tuple
    if successful, where `json` is JSON encoded string.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query_json(client(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_json(client, statement, params \\ [], opts \\ []) do
    query(client, statement, params, Keyword.merge(opts, output_format: :json))
  end

  @doc """
  Execute the query on the client and return the results as JSON encoded string.
    If an error occurs while executing the query, it will be raised as
    as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query_json!(client(), String.t(), list(), list(query_option())) :: result()
  def query_json!(client, statement, params \\ [], opts \\ []) do
    client
    |> query_json(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute the query on the client and return an optional singleton-returning
    result as a `{:ok, json}` tuple.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query_single_json(client(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_single_json(client, statement, params \\ [], opts \\ []) do
    query_json(client, statement, params, Keyword.merge(opts, cardinality: :at_most_one))
  end

  @doc """
  Execute the query on the client and return an optional singleton-returning result
    as JSON encoded string. If an error occurs while executing the query,
    it will be raised as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query_single_json!(client(), String.t(), list(), list(query_option())) :: result()
  def query_single_json!(client, statement, params \\ [], opts \\ []) do
    client
    |> query_single_json(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute the query on the client and return a singleton-returning result
    as a `{:ok, json}` tuple.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query_required_single_json(client(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_required_single_json(client, statement, params \\ [], opts \\ []) do
    query_single_json(client, statement, params, Keyword.merge(opts, required: true))
  end

  @doc """
  Execute the query on the client and return a singleton-returning result
    as JSON string. If an error occurs while executing the query,
    it will be raised as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec query_required_single_json!(client(), String.t(), list(), list(query_option())) ::
          result()
  def query_required_single_json!(client, statement, params \\ [], opts \\ []) do
    client
    |> query_required_single_json(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute an EdgeQL command or commands on the client without returning anything.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec execute(client(), String.t(), list(), list(query_option())) ::
          :ok | {:error, Exception.t()}
  def execute(client, statement, params \\ [], opts \\ []) do
    opts = Keyword.merge(opts, output_format: :none, script: true, raw: true)

    case query(client, statement, params, opts) do
      {:ok, _result} ->
        :ok

      {:error, _exc} = error ->
        error
    end
  end

  @doc """
  Execute an EdgeQL command or commands on the client without returning
    anything. If an error occurs while executing the query,
    it will be raised as an `EdgeDB.Error` exception.

  See `t:EdgeDB.query_option/0` for supported options.
  """
  @spec execute!(client(), String.t(), list(), list(query_option())) :: :ok
  def execute!(client, statement, params \\ [], opts \\ []) do
    opts = Keyword.merge(opts, output_format: :none, script: true, raw: true)
    query!(client, statement, params, opts)
    :ok
  end

  @doc """
  Open a retryable transaction loop.

  EdgeDB clients support transactions that are robust to network errors, server failure, and
    some transaction conflicts. For more information see
    [RFC](https://github.com/edgedb/rfcs/blob/master/text/1004-transactions-api.rst).

  The result of the transaction is the `{:ok, result}` tuple, where `result`
    is the result of the `callback` function executed in the transaction.

  To rollback an open transaction, use `EdgeDB.rollback/2`.

  `EdgeDB.transaction/3` calls **cannot** be nested more than once.

  ```iex
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> {:ok, tickets} = EdgeDB.transaction(client, fn client ->
  ...(2)>  EdgeDB.query!(client, "insert Ticket{ number := 2}")
  ...(2)>  EdgeDB.query!(client, "select Ticket")
  ...(2)> end)
  iex(3)> tickets
  #EdgeDB.Set<{#EdgeDB.Object<>}>
  ```

  See `t:EdgeDB.transaction_option/0` for supported options.
  """
  @spec transaction(client(), (EdgeDB.Client.t() -> result()), list(transaction_option())) ::
          {:ok, result()} | {:error, term()}

  def transaction(client, callback, opts \\ [])

  def transaction(%EdgeDB.Client{} = client, callback, opts) do
    callback = fn conn ->
      client = %EdgeDB.Client{client | conn: conn}

      EdgeDB.Borrower.borrow!(client.conn, :transaction, fn ->
        transaction_options = EdgeDB.Client.to_options(client)
        retry_options = Keyword.merge(transaction_options[:retry_options], opts[:retry] || [])
        transaction_options = Keyword.put(transaction_options, :retry_options, retry_options)
        retrying_transaction(client, callback, Keyword.merge(opts, transaction_options))
      end)
    end

    DBConnection.run(client.conn, callback, opts)
  end

  def transaction(client, callback, opts) do
    client
    |> to_client()
    |> transaction(callback, opts)
  end

  @doc """
  Rollback an open transaction.

  See `t:EdgeDB.rollback_option/0` for supported options.

  ```iex
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> {:error, :tx_rollback} =
  ...(2)>  EdgeDB.transaction(client, fn tx_conn ->
  ...(2)>   EdgeDB.rollback(tx_conn, reason: :tx_rollback)
  ...(2)>  end)

  ```
  """

  # 2 specs to satisfy the dialyser
  @spec rollback(EdgeDB.Client.t()) :: no_return()
  @spec rollback(EdgeDB.Client.t(), list(rollback_option())) :: no_return()

  def rollback(client, opts \\ []) do
    %EdgeDB.Client{conn: conn} = to_client(client)
    reason = opts[:reason] || :rollback
    DBConnection.rollback(conn, reason)
  end

  @doc """
  Mark the client as read-only.

  This function will mark the client as read-only, so any modifying queries will return errors.
  """
  @spec as_readonly(client()) :: client()
  def as_readonly(client) do
    client
    |> to_client()
    |> EdgeDB.Client.as_readonly()
  end

  @doc """
  Configure the client so that futher transactions are executed with custom transaction options.

  See `t:EdgeDB.transaction_option/0` for supported options.
  """
  @spec with_transaction_options(client(), list(EdgeDB.Client.transaction_option())) :: client()
  def with_transaction_options(client, opts) do
    client
    |> to_client()
    |> EdgeDB.Client.with_transaction_options(opts)
  end

  @doc """
  Configure the client so that futher transactions retries are executed with custom retries options.

  See `t:EdgeDB.Client.retry_option/0` for supported options.
  """
  @spec with_retry_options(client(), list(EdgeDB.Client.retry_option())) :: client()
  def with_retry_options(client, opts) do
    client
    |> to_client()
    |> EdgeDB.Client.with_retry_options(opts)
  end

  @doc """
  Returns client with adjusted state.

  See `EdgeDB.with_default_module/2`, `EdgeDB.with_module_aliases/2`/`EdgeDB.without_module_aliases/2`,
    `EdgeDB.with_config/2`/`EdgeDB.without_config/2`, `EdgeDB.with_globals/2`/`EdgeDB.without_globals/2`
    for more information.
  """
  @spec with_client_state(client(), EdgeDB.Client.State.t()) :: client()
  def with_client_state(client, state) do
    client
    |> to_client()
    |> EdgeDB.Client.with_state(state)
  end

  @doc """
  Returns client with adjusted default module.

  This is equivalent to using the `set module` command,
    or using the `reset module` command when giving `nil`.
  """
  @spec with_default_module(client(), String.t() | nil) :: client()
  def with_default_module(client, module \\ nil) do
    client
    |> to_client()
    |> EdgeDB.Client.with_default_module(module)
  end

  @doc """
  Returns client with adjusted module aliases.

  This is equivalent to using the `set alias` command.
  """
  @spec with_module_aliases(client(), %{String.t() => String.t()}) :: client()
  def with_module_aliases(client, aliases \\ %{}) do
    client
    |> to_client()
    |> EdgeDB.Client.with_module_aliases(aliases)
  end

  @doc """
  Returns client without specified module aliases.

  This is equivalent to using the `reset alias` command.
  """
  @spec without_module_aliases(client(), list(String.t())) :: client()
  def without_module_aliases(client, aliases \\ []) do
    client
    |> to_client()
    |> EdgeDB.Client.without_module_aliases(aliases)
  end

  @doc """
  Returns client with adjusted session config.

  This is equivalent to using the `configure session set` command.
  """
  @spec with_config(client(), %{atom() => term()}) :: client()
  def with_config(client, config \\ %{}) do
    client
    |> to_client()
    |> EdgeDB.Client.with_config(config)
  end

  @doc """
  Returns client without specified session config.

  This is equivalent to using the `configure session reset` command.
  """
  @spec without_config(client(), list(atom())) :: client()
  def without_config(client, config_keys \\ []) do
    client
    |> to_client()
    |> EdgeDB.Client.without_config(config_keys)
  end

  @doc """
  Returns client with adjusted global values.

  This is equivalent to using the `set global` command.
  """
  @spec with_globals(client(), %{String.t() => String.t()}) :: client()
  def with_globals(client, globals \\ %{}) do
    client
    |> to_client()
    |> EdgeDB.Client.with_globals(globals)
  end

  @doc """
  Returns client without specified globals.

  This is equivalent to using the `reset global` command.
  """
  @spec without_globals(client(), list(String.t())) :: client()
  def without_globals(client, global_names \\ []) do
    client
    |> to_client()
    |> EdgeDB.Client.without_globals(global_names)
  end

  defp parse_execute_query(client, query, params, opts) do
    client = to_client(client)
    EdgeDB.Borrower.ensure_unborrowed!(client.conn)
    parse_execute_query(1, client, query, params, opts)
  end

  defp parse_execute_query(attempt, client, query, params, opts) do
    execution_opts =
      client
      |> EdgeDB.Client.to_options()
      |> Keyword.merge(retry_options: opts[:retry] || [])

    case DBConnection.prepare_execute(client.conn, query, params, execution_opts) do
      {:ok, %EdgeDB.Query{} = q, %EdgeDB.Result{} = r} ->
        handle_query_result(q, r, opts)

      {:error, %EdgeDB.Error{} = exc} ->
        maybe_retry_readonly_query(attempt, exc, client, query, params, execution_opts)

      {:error, exc} ->
        {:error, exc}
    end
  rescue
    exc in EdgeDB.Error ->
      {:error, exc}
  end

  defp handle_query_result(query, result, opts) do
    cond do
      opts[:raw] ->
        {:ok, {query, result}}

      opts[:output_format] == :json ->
        # in result set there will be only a single value

        extracting_result =
          result
          |> Map.put(:cardinality, :at_most_one)
          |> EdgeDB.Result.extract()

        case extracting_result do
          {:ok, nil} ->
            {:ok, "null"}

          other ->
            other
        end

      true ->
        EdgeDB.Result.extract(result)
    end
  end

  # queries in transaction should be retried using EdgeDB.transaction/3
  defp maybe_retry_readonly_query(
         _attempt,
         exc,
         %EdgeDB.Client{conn: %DBConnection{conn_mode: :transaction}},
         _query,
         _params,
         _opts
       ) do
    {:error, exc}
  end

  defp maybe_retry_readonly_query(
         attempt,
         %EdgeDB.Error{query: %EdgeDB.Query{capabilities: capabilities}} = exc,
         client,
         query,
         params,
         opts
       ) do
    with true <- :readonly in capabilities,
         {:ok, backoff} <- retry?(exc, attempt, opts[:retry_options]) do
      Process.sleep(backoff)
      parse_execute_query(attempt + 1, client, query, params, opts)
    else
      _other ->
        {:error, exc}
    end
  end

  defp maybe_retry_readonly_query(_attempt, exc, _client, _query, _params, _opts) do
    {:error, exc}
  end

  defp retrying_transaction(client, callback, opts) do
    callback = fn conn ->
      callback.(%EdgeDB.Client{client | conn: conn})
    end

    retrying_transaction(1, client, callback, opts)
  end

  defp retrying_transaction(attempt, client, callback, opts) do
    DBConnection.transaction(client.conn, callback, opts)
  rescue
    exc in EdgeDB.Error ->
      case retry?(exc, attempt, opts[:retry_options]) do
        {:ok, backoff} ->
          Process.sleep(backoff)
          retrying_transaction(attempt + 1, client, callback, opts)

        :abort ->
          reraise exc, __STACKTRACE__
      end

    exc ->
      reraise exc, __STACKTRACE__
  end

  # we're hiding some internal stuff for EdgeDB.Error and dialyzer doesn't like that.
  @dialyzer {:nowarn_function, retry?: 3}
  defp retry?(exception, attempt, retry_opts) do
    rule = rule_for_retry(exception, retry_opts)

    if EdgeDB.Error.retry?(exception) and attempt <= rule[:attempts] do
      {:ok, rule[:backoff].(attempt)}
    else
      :abort
    end
  end

  defp rule_for_retry(%EdgeDB.Error{} = exception, retry_opts) do
    rule =
      cond do
        EdgeDB.Error.inheritor?(exception, EdgeDB.TransactionConflictError) ->
          Keyword.get(retry_opts, :transaction_conflict, [])

        EdgeDB.Error.inheritor?(exception, EdgeDB.ClientError) ->
          Keyword.get(retry_opts, :network_error, [])

        true ->
          []
      end

    default_rule = [
      attempts: 3,
      backoff: &default_backoff/1
    ]

    Keyword.merge(default_rule, rule)
  end

  defp default_backoff(attempt) do
    trunc(:math.pow(2, attempt) * Enum.random(0..100))
  end

  defp unwrap!(result) do
    case result do
      {:ok, value} ->
        value

      {:error, exc} ->
        raise exc
    end
  end

  defp to_client(%EdgeDB.Client{} = client) do
    client
  end

  defp to_client(client_name) when is_atom(client_name) do
    if pid = Process.whereis(client_name) do
      to_client(pid)
    else
      raise EdgeDB.InterfaceError.new("could not find process associated with #{client_name}")
    end
  end

  # ensure that client is really registered
  defp to_client(client_pid) do
    case Registry.lookup(EdgeDB.ClientsRegistry, client_pid) do
      [{_pid, client}] ->
        client

      _other ->
        raise EdgeDB.InterfaceError.new("client for pid(#{inspect(client_pid)}) not found")
    end
  end

  defp prepare_opts(opts) do
    opts
    |> Config.connect_opts()
    |> Keyword.put_new(:pool, EdgeDB.Pool)
    |> Keyword.put(:backoff_type, :stop)
  end

  defp register_client({:ok, pid} = result, opts) do
    client = %EdgeDB.Client{
      conn: pid,
      transaction_options: opts[:transaction] || [],
      retry_options: opts[:retry] || [],
      state: opts[:client_state] || %EdgeDB.Client.State{}
    }

    Registry.register(EdgeDB.ClientsRegistry, pid, client)

    result
  end

  defp register_client(result, _opts) do
    result
  end
end
