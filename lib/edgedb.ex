defmodule EdgeDB do
  @moduledoc """
  EdgeDB driver for Elixir.

  `EdgeDB` module provides an API to run a connection pool, query EdgeDB, perform transactions
    and subtransactions and their rollback.

  A simple example of how to use it:

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> EdgeDB.query!(pid, "
  ...(2)>   SELECT Person{
  ...(2)>     first_name,
  ...(2)>     middle_name,
  ...(2)>     last_name
  ...(2)>   } FILTER .last_name = <str>$last_name;
  ...(2)> ", last_name: "Radcliffe")
  #EdgeDB.Set<{#EdgeDB.Object<first_name := "Daniel", middle_name := "Jacob", last_name := "Radcliffe">}>
  ```
  """

  alias EdgeDB.Connection.{
    Config,
    InternalRequest
  }

  alias EdgeDB.Protocol.Enums

  @typedoc """
  Connection process name, pid or the same
    but wrapped in a separate structure that allows special actions on the connection.

  See `EdgeDB.as_readonly/1`, `EdgeDB.with_retry_options/2`, `EdgeDB.with_transaction_options/2`
    for more information.
  """
  @type connection() :: DBConnection.conn() | EdgeDB.WrappedConnection.t()

  @typedoc """
  Security modes for TLS connection to EdgeDB server.

  For more information, see [the official EdgeDB documentation on connection parameters](https://www.edgedb.com/docs/reference/connection#ref-reference-connection-granular).

  Supported options:

    * `:insecure` - trust a self-signed or user-signed TLS certificate, which is useful for local development.
    * `:no_host_verification` - verify the TLS certificate, but not the host name.
    * `:strict` - verify both the TLS certificate and the hostname.
    * `:default` - the same as `:strict`.
  """
  @type tls_security() :: :insecure | :no_host_verification | :strict | :default

  # NOTE: :command_timeout and :server_settings
  # options added only for compatability with other drivers and aren't used right now
  @typedoc """
  Parameters for connecting to an EdgeDB instance and configuring the connection itself.

  EdgeDB clients allow a very flexible way to define how to connect to an instance.
    For more information, see [the official EdgeDB documentation on connection parameters](https://www.edgedb.com/docs/reference/connection#ref-reference-connection-granular).

  Supported options:

    * `:dsn` - DSN that defines the primary information that can be used to connect to the instance.
    * `:credentials` - a JSON string containing the instance parameters to connect.
    * `:credentials_file` - the path to the instance credentials file containing the instance parameters to connect to.
    * `:host` - the host name of the instance to connect to.
    * `:port` - the port number of the instance to connect to.
    * `:database` - the name of the database to connect to.
    * `:user` - the user name to connect to.
    * `:password` - the user password to connect.
    * `:tls_ca` - TLS certificate to be used when connecting to the instance.
    * `:tls_ca_path` - the path to the TLS certificate to be used when connecting to the instance.
    * `:tls_security` - security mode for the TLS connection. See `t:tls_security/0`.
    * `:timeout` - timeout for TCP operations with the database, such as connecting to it, sending or receiving data.
    * `:command_timeout` - *not in use right now and added for compatibility with the official drivers*.
    * `:server_settings` - *not in use right now and added for compatibility with the official drivers*.
    * `:tcp` - options for the TCP connection.
    * `:ssl` - options for TLS connection.
    * `:transaction` - options for EdgeDB transactions, which correspond to
      [the EdgeQL transaction statement](https://www.edgedb.com/docs/reference/edgeql/tx_start#statement::start-transaction).
      See `t:edgedb_transaction_option/0`.
    * `:retry` - options to retry transactions in case of errors. See `t:retry_option/0`.
    * `:codecs` - list of custom codecs for EdgeDB scalars.
    * `:connection` - module that implements the `DBConnection` behavior for EdgeDB.
      For tests, it's possible to use `EdgeDB.Sandbox` to support automatic rollback after tests are done.
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
          | {:transaction, list(edgedb_transaction_option())}
          | {:retry, list(retry_option())}
          | {:codecs, list(module())}
          | {:connection, module()}

  @typedoc """
  Options for `EdgeDB.start_link/1`.

  See `t:connect_option/0` and `t:DBConnection.start_option/0`.
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
    * `:io_format` - preferred format of query result.
    * `:retry` - options for read-only queries retries.
    * `:raw` - flag to return internal driver structures for inspecting.
    * other - check `t:DBConnection.start_option/0`.
  """
  @type query_option() ::
          {:cardinality, Enums.cardinality()}
          | {:io_format, Enums.io_format()}
          | {:retry, list(retry_option())}
          | {:raw, boolean()}
          | DBConnection.option()

  @typedoc """
  Options for EdgeDB transactions.

  These options are responsible for building the appropriate EdgeQL statement to start transactions and
    they correspond to [the EdgeQL transaction statement](https://www.edgedb.com/docs/reference/edgeql/tx_start#statement::start-transaction).

  Supported options:

    * `:isolation` - If `:serializable` is used, the built statement will use the `ISOLATION SERIALIZABLE` mode.
      Otherwise, if `:repeatable_read` is used, the built statement will use the `ISOLATION REPEATABLE READ` mode.
      The default is `:repeatable_read`.
    * `:readonly` - if set to `true` then the built statement will use `READ ONLY` mode,
      otherwise `READ WRITE` will be used. The default is `false`.
    * `:deferrable` - if set to `true` then the built statement will use `DEFERRABLE` mode,
      otherwise `NOT DEFERRABLE` will be used. The default is `false`.
  """
  @type edgedb_transaction_option() ::
          {:isolation, :repeatable_read | :serializable}
          | {:readonly, boolean()}
          | {:deferrable, boolean()}

  @typedoc """
  Options for `EdgeDB.transaction/3`.

  See `t:edgedb_transaction_option/0` and `t:DBConnection.start_option/0`.
  """
  @type transaction_option() ::
          edgedb_transaction_option()
          | {:retry, list(retry_option())}
          | DBConnection.option()

  @typedoc """
  Options for `EdgeDB.rollback/2`.

  Supported options:

    * `:reason` - the reason for the rollback. Will be returned from `EdgeDB.transaction/3`
      or `EdgeDB.subtransaction/2` as a `{:error, reason}` tuple in case block execution is interrupted.
    * `:continue` - can be used when the connection is in a subtransaction
      and rollback should not stop further execution of the subtransaction block. See `EdgeDB.subtransaction/2`.
  """
  @type rollback_option() ::
          {:reason, term()}
          | {:continue, boolean()}

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

  @typedoc """
  A tuple of the executed `EdgeDB.Query` and the received `EdgeDB.Result`.

  This tuple can be useful if you want to get the internal structures of the driver and inspect them,
    but in most cases you will not use it.
  """
  @type raw_result() :: {EdgeDB.Query.t(), EdgeDB.Result.t()}

  @typedoc """
  The result that will be returned if the `EdgeDB.query*/4` function succeeds.
  """
  @type result() :: EdgeDB.Set.t() | term() | raw_result()

  @doc """
  Creates a pool of EdgeDB connections linked to the current process.

  If the first argument is a string, it will be assumed to be the DSN and passed as
    `[dsn: dsn]` keyword list to connect.

  ```elixir
  iex(1)> {:ok, _pid} = EdgeDB.start_link("edgedb://edgedb:edgedb@localhost:5656/edgedb")
  ```

  Otherwise, if the first argument is a list, it will be used as is to connect.
    See `t:start_option/0` for supported connection options.

  ```elixir
  iex(1)> {:ok, _pid} = EdgeDB.start_link(instance: "edgedb_elixir")
  ```
  """
  def start_link(opts \\ [])

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(dsn) when is_binary(dsn) do
    opts = Config.connect_opts(dsn: dsn)
    connection = Keyword.get(opts, :connection, EdgeDB.Connection)
    DBConnection.start_link(connection, opts)
  end

  @spec start_link(list(start_option())) :: GenServer.on_start()
  def start_link(opts) do
    opts = Config.connect_opts(opts)
    connection = Keyword.get(opts, :connection, EdgeDB.Connection)
    DBConnection.start_link(connection, opts)
  end

  @doc """
  Creates a pool of EdgeDB connections linked to the current process.

  The first argument is the string which will be assumed as the DSN and passed as
    `[dsn: dsn]` keyword list along with other options to connect.
    See `t:start_option/0` for supported connection options.

  ```elixir
  iex(1)> {:ok, _pid} = EdgeDB.start_link("edgedb://edgedb:edgedb@localhost:5656/edgedb", tls_security: :insecure)
  ```
  """
  @spec start_link(String.t(), list(start_option())) :: GenServer.on_start()
  def start_link(dsn, opts) do
    opts =
      opts
      |> Keyword.put(:dsn, dsn)
      |> Config.connect_opts()

    connection = Keyword.get(opts, :connection, EdgeDB.Connection)
    DBConnection.start_link(connection, opts)
  end

  @doc """
  Creates a child specification for the supervisor to start the EdgeDB pool.

  See `t:start_option/0` for supported connection options.
  """
  @spec child_spec(list(start_option())) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    opts = Config.connect_opts(opts)
    connection = Keyword.get(opts, :connection, EdgeDB.Connection)
    DBConnection.child_spec(connection, opts)
  end

  @doc """
  Execute the query on the connection and return the results as a `{:ok, set}` tuple
    if successful, where `set` is `EdgeDB.Set`.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> {:ok, %EdgeDB.Set{} = set} = EdgeDB.query(pid, "SELECT 42")
  iex(3)> set
  #EdgeDB.Set<{42}>
  ```

  If an error occurs, it will be returned as a `{:error, exception}` tuple
    where `exception` is `EdgeDB.Error`.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> {:error, %EdgeDB.Error{} = error} = EdgeDB.query(pid, "SELECT UndefinedType")
  iex(2)> raise error
  ** (EdgeDB.Error) InvalidReferenceError: object type or alias 'default::UndefinedType' does not exist
  ```

  If a query has arguments, they can be passed as a list for a query with positional arguments
    or as a list of keywords for a query with named arguments.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> {:ok, %EdgeDB.Set{} = set} = EdgeDB.query(pid, "SELECT <int64>$0", [42])
  iex(3)> set
  #EdgeDB.Set<{42}>
  ```

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> {:ok, %EdgeDB.Set{} = set} = EdgeDB.query(pid, "SELECT <int64>$arg", arg: 42)
  iex(3)> set
  #EdgeDB.Set<{42}>
  ```

  ### Automatic retries of read-only queries

  If the driver is able to recognize the query as a read-only query
    (i.e. the query does not change the data in the database using `DELETE`, `INSERT` or other statements),
    then the driver will try to repeat the query automatically (as long as the query is not executed in a transaction,
    because then [retrying transactions](`EdgeDB.transaction/3`) are used).

  See `t:query_option/0` for supported options.
  """
  @spec query(connection(), String.t(), list() | Keyword.t(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query(conn, statement, params \\ [], opts \\ []) do
    q = %EdgeDB.Query{
      statement: statement,
      cardinality: Keyword.get(opts, :cardinality, :many),
      io_format: Keyword.get(opts, :io_format, :binary),
      required: Keyword.get(opts, :required, false),
      params: params
    }

    prepare_execute_query(conn, q, q.params, opts)
  end

  @doc """
  Execute the query on the connection and return the results as `EdgeDB.Set`.
    If an error occurs while executing the query, it will be raised as
    as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query!(connection(), String.t(), list(), list(query_option())) :: result()
  def query!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute the query on the connection and return an optional singleton-returning
    result as a `{:ok, result}` tuple.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query_single(connection(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_single(conn, statement, params \\ [], opts \\ []) do
    query(conn, statement, params, Keyword.merge(opts, cardinality: :at_most_one))
  end

  @doc """
  Execute the query on the connection and return an optional singleton-returning result.
    If an error occurs while executing the query, it will be raised
    as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query_single!(connection(), String.t(), list(), list(query_option())) :: result()
  def query_single!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query_single(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute the query on the connection and return a singleton-returning result
    as a `{:ok, result}` tuple.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query_required_single(connection(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_required_single(conn, statement, params \\ [], opts \\ []) do
    query_single(conn, statement, params, Keyword.merge(opts, required: true))
  end

  @doc """
  Execute the query on the connection and return a singleton-returning result.
    If an error occurs while executing the query, it will be raised
    as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query_required_single!(connection(), String.t(), list(), list(query_option())) :: result()
  def query_required_single!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query_required_single(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute the query on the connection and return the results as a `{:ok, json}` tuple
    if successful, where `json` is JSON encoded string.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query_json(connection(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_json(conn, statement, params \\ [], opts \\ []) do
    query(conn, statement, params, Keyword.merge(opts, io_format: :json))
  end

  @doc """
  Execute the query on the connection and return the results as JSON encoded string.
    If an error occurs while executing the query, it will be raised as
    as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query_json!(connection(), String.t(), list(), list(query_option())) :: result()
  def query_json!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query_json(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute the query on the connection and return an optional singleton-returning
    result as a `{:ok, json}` tuple.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query_single_json(connection(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_single_json(conn, statement, params \\ [], opts \\ []) do
    query_json(conn, statement, params, Keyword.merge(opts, cardinality: :at_most_one))
  end

  @doc """
  Execute the query on the connection and return an optional singleton-returning result
    as JSON encoded string. If an error occurs while executing the query,
    it will be raised as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query_single_json!(connection(), String.t(), list(), list(query_option())) :: result()
  def query_single_json!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query_single_json(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Execute the query on the connection and return a singleton-returning result
    as a `{:ok, json}` tuple.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query_required_single_json(connection(), String.t(), list(), list(query_option())) ::
          {:ok, result()}
          | {:error, Exception.t()}
  def query_required_single_json(conn, statement, params \\ [], opts \\ []) do
    query_single_json(conn, statement, params, Keyword.merge(opts, required: true))
  end

  @doc """
  Execute the query on the connection and return a singleton-returning result
    as JSON string. If an error occurs while executing the query,
    it will be raised as an `EdgeDB.Error` exception.

  For the general usage, see `EdgeDB.query/4`.

  See `t:query_option/0` for supported options.
  """
  @spec query_required_single_json!(connection(), String.t(), list(), list(query_option())) ::
          result()
  def query_required_single_json!(conn, statement, params \\ [], opts \\ []) do
    conn
    |> query_required_single_json(statement, params, opts)
    |> unwrap!()
  end

  @doc """
  Open a retryable transaction loop.

  EdgeDB clients support transactions that are robust to network errors, server failure, and
    some transaction conflicts. For more information see
    [RFC](https://github.com/edgedb/rfcs/blob/master/text/1004-transactions-api.rst).

  The result of the transaction is the `{:ok, result}` tuple, where `result`
    is the result of the `callback` function executed in the transaction.

  To rollback an open transaction, use `EdgeDB.rollback/2`.

  `EdgeDB.transaction/3` calls **cannot** be nested more than once. If you want to start a new transaction
    inside an already running one, you should use `EdgeDB.subtransaction/2`,
    which will declare a new savepoint for the current transaction.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> {:ok, tickets} = EdgeDB.transaction(pid, fn conn ->
  ...(2)>  EdgeDB.query!(conn, "INSERT Ticket{ number := 2}")
  ...(2)>  EdgeDB.query!(conn, "SELECT Ticket")
  ...(2)> end)
  iex(3)> tickets
  #EdgeDB.Set<{#EdgeDB.Object<>}>
  ```

  See `t:transaction_option/0` for supported options.
  """
  @spec transaction(
          connection(),
          (DBConnection.t() -> result()),
          list(transaction_option())
        ) ::
          {:ok, result()}
          | {:error, term()}

  def transaction(conn, callback, opts \\ [])

  def transaction(%EdgeDB.WrappedConnection{} = conn, callback, opts) do
    execute_wrapped_callbacks(conn, &transaction(&1, callback, opts))
  end

  def transaction(conn, callback, opts) do
    EdgeDB.Borrower.borrow!(conn, :transaction, fn ->
      retrying_transaction(conn, callback, opts)
    end)
  end

  @doc """
  Open a subtransaction inside an already open transaction.

  The result of the subtransaction is the `{:ok, result}` tuple, where `result`
    is the result of the `callback` function executed in the subtransaction.

  To rollback an open subtransaction, use `EdgeDB.rollback/2`. A subtransaction can be rolled back
    without exiting the subtransaction block. See `t:rollback_option/0`.

  `EdgeDB.subtransaction/2` calls **can** be nested multiple times. Each new call to `EdgeDB.subtransaction/2`
    will declare a new savepoint for the current transaction.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> {:ok, tickets} =
  ...(2)>  EdgeDB.transaction(pid, fn tx_conn ->
  ...(2)>    {:ok, tickets} =
  ...(2)>      EdgeDB.subtransaction(tx_conn, fn subtx_conn1 ->
  ...(2)>        {:ok, tickets} =
  ...(2)>          EdgeDB.subtransaction(subtx_conn1, fn subtx_conn2 ->
  ...(2)>            EdgeDB.query!(subtx_conn2, "INSERT Ticket{ number := 2}")
  ...(2)>            EdgeDB.query!(subtx_conn2, "SELECT Ticket{ number }")
  ...(2)>          end)
  ...(2)>        tickets
  ...(2)>      end)
  ...(2)>    tickets
  ...(2)>  end)
  iex(3)> tickets
  #EdgeDB.Set<{#EdgeDB.Object<number := 2>}>
  ```
  """
  @spec subtransaction(DBConnection.conn(), (DBConnection.t() -> result())) ::
          {:ok, result()} | {:error, term()}

  def subtransaction(%DBConnection{conn_mode: :transaction} = conn, callback) do
    EdgeDB.Borrower.borrow!(conn, :subtransaction, fn ->
      {:ok, subtransaction_pid} =
        DBConnection.start_link(EdgeDB.Subtransaction, conn: conn, backoff_type: :stop)

      try do
        DBConnection.transaction(subtransaction_pid, callback)
      rescue
        exc ->
          Process.unlink(subtransaction_pid)
          Process.exit(subtransaction_pid, :kill)

          reraise exc, __STACKTRACE__
      else
        result ->
          Process.unlink(subtransaction_pid)
          Process.exit(subtransaction_pid, :kill)
          result
      end
    end)
  end

  def subtransaction(_conn, _callback) do
    raise EdgeDB.Error.interface_error(
            "EdgeDB.subtransaction/2 can be used only with connection " <>
              "that is already in transaction (check out EdgeDB.transaction/3) " <>
              "or in another subtransaction"
          )
  end

  @spec subtransaction!(DBConnection.conn(), (DBConnection.conn() -> result())) :: result()
  def subtransaction!(conn, callback) do
    case subtransaction(conn, callback) do
      {:ok, result} ->
        result

      {:error, rollback_reason} ->
        rollback(conn, reason: rollback_reason)
    end
  end

  @doc """
  Rollback an open transaction or subtransaction.

  By default `EdgeDB.rollback/2` will abort the transaction/subtransaction function and return to the external scope.
    But subtransactions can skip this behavior and continue executing after the rollback using the `:continue` option.

  See `t:rollback_option/0` for supported options.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> {:error, :tx_rollback} =
  ...(2)>  EdgeDB.transaction(pid, fn tx_conn ->
  ...(2)>   EdgeDB.rollback(tx_conn, reason: :tx_rollback)
  ...(2)>  end)
  ```

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> {:error, :subtx_rollback} =
  ...(2)>  EdgeDB.transaction(pid, fn tx_conn ->
  ...(2)>   {:error, reason} =
  ...(2)>     EdgeDB.subtransaction(tx_conn, fn subtx_conn ->
  ...(2)>      EdgeDB.rollback(subtx_conn, reason: :subtx_rollback)
  ...(2)>     end)
  ...(2)>    EdgeDB.rollback(tx_conn, reason: reason)
  ...(2)>  end)
  ```

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> {:ok, 42} =
  ...(2)>  EdgeDB.transaction(pid, fn tx_conn ->
  ...(2)>   {:ok, result} =
  ...(2)>     EdgeDB.subtransaction(tx_conn, fn subtx_conn ->
  ...(2)>      EdgeDB.rollback(subtx_conn, continue: true)
  ...(2)>      EdgeDB.query_required_single!(subtx_conn, "SELECT 42")
  ...(2)>     end)
  ...(2)>   result
  ...(2)>  end)
  ```
  """
  @spec rollback(connection(), list(rollback_option())) :: :ok | no_return()
  def rollback(conn, opts \\ []) do
    reason = opts[:reason] || :rollback

    with true <- opts[:continue],
         {:ok, _query, true} <-
           DBConnection.execute(conn, %InternalRequest{request: :is_subtransaction}, [], []),
         {:ok, _query, _result} <-
           DBConnection.execute(conn, %InternalRequest{request: :rollback}, [], []) do
      :ok
    else
      {:error, exc} ->
        raise exc

      _other ->
        DBConnection.rollback(conn, reason)
    end
  end

  @doc """
  Mark the connection as read-only.

  This function will mark the connection as read-only, so any modifying queries will return errors.
  """
  @spec as_readonly(connection()) :: connection()
  def as_readonly(conn) do
    EdgeDB.WrappedConnection.wrap(conn, fn conn, callback ->
      with {:ok, _query, capabilities} <-
             DBConnection.execute(conn, %InternalRequest{request: :capabilities}, []),
           {:ok, _query, _result} <-
             DBConnection.execute(conn, %InternalRequest{request: :set_capabilities}, %{
               capabilities: [:readonly]
             }) do
        defer(fn -> callback.(conn) end, fn ->
          DBConnection.execute!(conn, %InternalRequest{request: :set_capabilities}, %{
            capabilities: capabilities
          })
        end)
      end
    end)
  end

  @doc """
  Configure the connection so that futher transactions are executed with custom transaction options.

  See `t:edgedb_transaction_option/0` for supported options.
  """
  @spec with_transaction_options(connection(), list(edgedb_transaction_option())) :: connection()
  def with_transaction_options(conn, opts) do
    EdgeDB.WrappedConnection.wrap(conn, fn conn, callback ->
      with {:ok, _query, transaction_opts} <-
             DBConnection.execute(conn, %InternalRequest{request: :transaction_options}, []),
           {:ok, _query, _result} <-
             DBConnection.execute(conn, %InternalRequest{request: :set_transaction_options}, %{
               options: opts
             }) do
        defer(fn -> callback.(conn) end, fn ->
          DBConnection.execute!(conn, %InternalRequest{request: :set_transaction_options}, %{
            options: transaction_opts
          })
        end)
      end
    end)
  end

  @doc """
  Configure the connection so that futher transactions retries are executed with custom retries options.

  See `t:retry_option/0` for supported options.
  """
  @spec with_retry_options(connection(), list(retry_option())) :: connection()
  def with_retry_options(conn, opts) do
    EdgeDB.WrappedConnection.wrap(conn, fn conn, callback ->
      with {:ok, _query, retry_opts} <-
             DBConnection.execute(conn, %InternalRequest{request: :retry_options}, []),
           {:ok, _query, _result} <-
             DBConnection.execute(conn, %InternalRequest{request: :set_retry_options}, %{
               options: opts
             }) do
        defer(fn -> callback.(conn) end, fn ->
          request = %InternalRequest{request: :set_retry_options}
          DBConnection.execute!(conn, request, %{options: retry_opts}, replace: true)
        end)
      end
    end)
  end

  defp prepare_execute_query(
         %EdgeDB.WrappedConnection{conn: conn, callbacks: callbacks},
         query,
         params,
         opts
       ) do
    prepare_execute_callback = &prepare_execute_query(&1, query, params, opts)

    execution_callback =
      Enum.reduce([prepare_execute_callback | callbacks], fn next, last ->
        &next.(&1, last)
      end)

    execution_callback.(conn)
  end

  defp prepare_execute_query(conn, query, params, opts) do
    EdgeDB.Borrower.ensure_unborrowed!(conn)

    with {:ok, _query, retry_opts} <-
           DBConnection.execute(conn, %InternalRequest{request: :retry_options}, []) do
      retry_opts = Keyword.merge(retry_opts, opts[:retry] || [])
      prepare_execute_query(1, conn, query, params, Keyword.merge(opts, retry: retry_opts))
    end
  end

  defp prepare_execute_query(attempt, conn, query, params, opts) do
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, %EdgeDB.Query{} = q, %EdgeDB.Result{} = r} ->
        handle_query_result(q, r, opts)

      {:error, %EdgeDB.Error{} = exc} ->
        maybe_retry_readonly_query(attempt, exc, conn, query, params, opts)

      {:error, exc} ->
        {:error, exc}
    end
  end

  defp handle_query_result(query, result, opts) do
    cond do
      opts[:raw] ->
        {:ok, {query, result}}

      opts[:io_format] == :json ->
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
         %DBConnection{conn_mode: :transaction},
         _query,
         _params,
         _opts
       ) do
    {:error, exc}
  end

  defp maybe_retry_readonly_query(
         attempt,
         %EdgeDB.Error{query: %EdgeDB.Query{capabilities: capabilities}} = exc,
         conn,
         query,
         params,
         opts
       ) do
    with true <- :readonly in capabilities,
         {:ok, backoff} <- retry?(exc, attempt, opts[:retry] || []) do
      Process.sleep(backoff)
      prepare_execute_query(attempt + 1, conn, query, params, opts)
    else
      _other ->
        {:error, exc}
    end
  end

  defp maybe_retry_readonly_query(_attempt, exc, _conn, _query, _params, _opts) do
    {:error, exc}
  end

  defp retrying_transaction(conn, callback, opts) do
    with {:ok, _query, retry_opts} <-
           DBConnection.execute(conn, %InternalRequest{request: :retry_options}, []) do
      retrying_transaction(1, conn, callback, Keyword.merge(retry_opts, opts[:retry] || []))
    end
  end

  defp retrying_transaction(attempt, conn, callback, retry_opts) do
    DBConnection.transaction(conn, callback, retry_opts)
  rescue
    exc in EdgeDB.Error ->
      case retry?(exc, attempt, retry_opts) do
        {:ok, backoff} ->
          Process.sleep(backoff)
          retrying_transaction(attempt + 1, conn, callback, retry_opts)

        :abort ->
          reraise exc, __STACKTRACE__
      end

    exc ->
      reraise exc, __STACKTRACE__
  end

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
        EdgeDB.Error.inheritor?(exception, :transaction_conflict_error) ->
          Keyword.get(retry_opts, :transaction_conflict, [])

        EdgeDB.Error.inheritor?(exception, :client_error) ->
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

  defp execute_wrapped_callbacks(
         %EdgeDB.WrappedConnection{conn: conn, callbacks: callbacks},
         callback
       ) do
    DBConnection.run(conn, fn conn ->
      Enum.reduce([callback | callbacks], fn next, last ->
        &next.(&1, last)
      end).(conn)
    end)
  end

  defp defer(original_callback, deferred_callback) do
    original_callback.()
  rescue
    exc ->
      deferred_callback.()
      reraise exc, __STACKTRACE__
  else
    result ->
      deferred_callback.()
      result
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
end
