.. _edgedb-elixir-api-api:

API
===

EdgeDB
------

EdgeDB client for Elixir.

``EdgeDB`` module provides an API to run a connection pool, query EdgeDB, perform transactions and their rollback.

A simple example of how to use it:

.. code:: iex

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> EdgeDB.query!(client, """
   ...(2)>   select v1::Person{
   ...(2)>     first_name,
   ...(2)>     middle_name,
   ...(2)>     last_name
   ...(2)>   } filter .last_name = <str>$last_name;
   ...(2)> """, last_name: "Radcliffe")
   #EdgeDB.Set<{#EdgeDB.Object<first_name := "Daniel", middle_name := "Jacob", last_name := "Radcliffe">}>

Types
~~~~~

*type* ``EdgeDB.client/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.client() :: DBConnection.conn() | EdgeDB.Client.t()

Connection pool process name, pid or the separate structure that allows adjusted configuration for queries executed on the connection.

See ``EdgeDB.as_readonly/1``, ``EdgeDB.with_retry_options/2``, ``EdgeDB.with_transaction_options/2`` for more information.

*type* ``EdgeDB.connect_option/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.connect_option() ::
     {:dsn, String.t()}
     | {:credentials, String.t()}
     | {:credentials_file, Path.t()}
     | {:host, String.t()}
     | {:port, :inet.port_number()}
     | {:database, String.t()}
     | {:branch, String.t()}
     | {:user, String.t()}
     | {:password, String.t()}
     | {:tls_ca, String.t()}
     | {:tls_ca_file, Path.t()}
     | {:tls_security, tls_security()}
     | {:timeout, timeout()}
     | {:command_timeout, timeout()}
     | {:server_settings, map()}
     | {:tcp, [:gen_tcp.option()]}
     | {:ssl, [:ssl.tls_client_option()]}
     | {:transaction, [EdgeDB.Client.transaction_option()]}
     | {:retry, [EdgeDB.Client.retry_option()]}
     | {:codecs, [module()]}
     | {:connection, module()}
     | {:max_concurrency, pos_integer()}
     | {:client_state, EdgeDB.Client.State.t()}

Parameters for connecting to an EdgeDB instance and configuring the connection itself.

EdgeDB clients allow a very flexible way to define how to connect to an instance. For more information, see `the EdgeDB documentation on
connection parameters`_.

Supported options:

-  ``:dsn`` - DSN that defines the primary information that can be used to connect to the instance.
-  ``:credentials`` - a JSON string containing the instance parameters to connect.
-  ``:credentials_file`` - the path to the instance credentials file containing the instance parameters to connect to.
-  ``:host`` - the host name of the instance to connect to.
-  ``:port`` - the port number of the instance to connect to.
-  ``:database`` - the name of the database to connect to.
-  ``:branch`` - the name of the branch to connect to.
-  ``:user`` - the user name to connect to.
-  ``:password`` - the user password to connect.
-  ``:secret_key`` - the secret key to be used for authentication.
-  ``:tls_ca`` - TLS certificate to be used when connecting to the instance.
-  ``:tls_ca_path`` - the path to the TLS certificate to be used when connecting to the instance.
-  ``:tls_security`` - security mode for the TLS connection. See ``EdgeDB.tls_security/0``.
-  ``:timeout`` - timeout for TCP operations with the database, such as connecting to it, sending or receiving data.
-  ``:command_timeout`` - *not in use right now and added for compatibility with other clients*.
-  ``:server_settings`` - *not in use right now and added for compatibility with other clients*.
-  ``:tcp`` - options for the TCP connection.
-  ``:ssl`` - options for TLS connection.
-  ``:transaction`` - options for EdgeDB transactions, which correspond to `the EdgeQL transaction statement`_. See
   ``EdgeDB.Client.transaction_option/0``.
-  ``:retry`` - options to retry transactions in case of errors. See ``EdgeDB.Client.retry_option/0``.
-  ``:codecs`` - list of custom codecs for EdgeDB scalars.
-  ``:connection`` - module that implements the ``DBConnection`` behavior for EdgeDB. For tests, it’s possible to use ``EdgeDB.Sandbox`` to
   support automatic rollback after tests are done.
-  ``:max_concurrency`` - maximum number of pool connections, despite what EdgeDB recommends.
-  ``:client_state`` - an ``EdgeDB.Client.State`` struct that will be used in queries by default.

*type* ``EdgeDB.query_option/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.query_option() ::
     {:cardinality, EdgeDB.Protocol.Enums.cardinality()}
     | {:output_format, EdgeDB.Protocol.Enums.output_format()}
     | {:retry, [EdgeDB.Client.retry_option()]}
     | {:script, boolean()}
     | DBConnection.option()

Options for ``EdgeDB.query*/4`` functions.

These options can be used with the following functions:

-  ``EdgeDB.query/4``
-  ``EdgeDB.query!/4``
-  ``EdgeDB.query_single/4``
-  ``EdgeDB.query_single!/4``
-  ``EdgeDB.query_required_single/4``
-  ``EdgeDB.query_required_single!/4``
-  ``EdgeDB.query_json/4``
-  ``EdgeDB.query_json!/4``
-  ``EdgeDB.query_single_json/4``
-  ``EdgeDB.query_single_json!/4``
-  ``EdgeDB.query_required_single_json/4``
-  ``EdgeDB.query_required_single_json!/4``

Supported options:

-  ``:cardinality`` - expected number of items in set.
-  ``:output_format`` - preferred format of query result.
-  ``:retry`` - options for read-only queries retries.
-  other - check ``DBConnection.option/0``.

*type* ``EdgeDB.result/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.result() :: EdgeDB.Set.t() | term()

The result that will be returned if the ``EdgeDB.query*/4`` function succeeds.

*type* ``EdgeDB.rollback_option/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.rollback_option() :: {:reason, term()}

Options for ``EdgeDB.rollback/2``.

Supported options:

-  ``:reason`` - the reason for the rollback. Will be returned from ``EdgeDB.transaction/3`` as a ``{:error, reason}`` tuple in case block
   execution is interrupted.

*type* ``EdgeDB.start_option/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.start_option() :: connect_option() | DBConnection.start_option()

Options for ``EdgeDB.start_link/1``.

See ``EdgeDB.connect_option/0`` and ``DBConnection.start_option/0``.

*type* ``EdgeDB.tls_security/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.tls_security() :: :insecure | :no_host_verification | :strict | :default

Security modes for TLS connection to EdgeDB server.

For more information, see `the EdgeDB documentation on connection parameters`_.

Supported options:

-  ``:insecure`` - trust a self-signed or user-signed TLS certificate, which is useful for local development.
-  ``:no_host_verification`` - verify the TLS certificate, but not the host name.
-  ``:strict`` - verify both the TLS certificate and the hostname.
-  ``:default`` - the same as ``:strict``.

*type* ``EdgeDB.transaction_option/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.transaction_option() ::
     EdgeDB.Client.transaction_option()
     | {:retry, [EdgeDB.Client.retry_option()]}
     | DBConnection.option()

Options for ``EdgeDB.transaction/3``.

See ``EdgeDB.Client.transaction_option/0``, ``EdgeDB.Client.retry_option/0`` and ``DBConnection.option/0``.

Functions
~~~~~~~~~

*function* ``EdgeDB.as_readonly(client)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.as_readonly(client()) :: client()

Mark the client as read-only.

This function will mark the client as read-only, so any modifying queries will return errors.

*function* ``EdgeDB.child_spec(opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.child_spec([start_option()]) :: Supervisor.child_spec()

Creates a child specification for the supervisor to start the EdgeDB pool.

See ``EdgeDB.start_option/0`` for supported connection options.

*function* ``EdgeDB.execute(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.execute(client(), String.t(), list(), [query_option()]) :: :ok | {:error, Exception.t()}

Execute an EdgeQL command or commands on the client without returning anything.

See ``EdgeDB.query_option/0`` for supported options.

.. _function-edgedb.executeclient-statement-params-opts-1:

*function* ``EdgeDB.execute!(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.execute!(client(), String.t(), list(), [query_option()]) :: :ok

Execute an EdgeQL command or commands on the client without returning anything. If an error occurs while executing the query, it will be raised
as an ``EdgeDB.Error`` exception.

See ``EdgeDB.query_option/0`` for supported options.

*function* ``EdgeDB.query(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query(client(), String.t(), list() | Keyword.t(), [query_option()]) ::
     {:ok, result()} | {:error, Exception.t()}

Execute the query on the client and return the results as a ``{:ok, set}`` tuple if successful, where ``set`` is ``EdgeDB.Set``.

.. code:: iex

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> {:ok, set} = EdgeDB.query(client, "select 42")
   iex(3)> set
   #EdgeDB.Set<{42}>

If an error occurs, it will be returned as a ``{:error, exception}`` tuple where ``exception`` is ``EdgeDB.Error``.

.. code:: iex

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> {:error, %EdgeDB.Error{} = error} = EdgeDB.query(client, "select UndefinedType")
   iex(3)> raise error
   ** (EdgeDB.Error) InvalidReferenceError: object type or alias 'default::UndefinedType' does not exist
     ┌─ query:1:8
     │
   1 │   select UndefinedType
     │          ^^^^^^^^^^^^^ error

If a query has arguments, they can be passed as a list for a query with positional arguments or as a list of keywords for a query with named
arguments.

.. code:: iex

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> {:ok, set} = EdgeDB.query(client, "select <int64>$0", [42])
   iex(3)> set
   #EdgeDB.Set<{42}>

.. code:: iex

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> {:ok, set} = EdgeDB.query(client, "select <int64>$arg", arg: 42)
   iex(3)> set
   #EdgeDB.Set<{42}>

Automatic retries of read-only queries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If the client is able to recognize the query as a read-only query (i.e. the query does not change the data in the database using ``delete``,
``insert`` or other statements), then the client will try to repeat the query automatically (as long as the query is not executed in a
transaction, because then retrying transactions via ``EdgeDB.transaction/3`` are used).

See ``EdgeDB.query_option/0`` for supported options.

.. _function-edgedb.queryclient-statement-params-opts-1:

*function* ``EdgeDB.query!(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query!(client(), String.t(), list(), [query_option()]) :: result()

Execute the query on the client and return the results as ``EdgeDB.Set``. If an error occurs while executing the query, it will be raised as as
an ``EdgeDB.Error`` exception.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

*function* ``EdgeDB.query_json(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query_json(client(), String.t(), list(), [query_option()]) ::
     {:ok, result()} | {:error, Exception.t()}

Execute the query on the client and return the results as a ``{:ok, json}`` tuple if successful, where ``json`` is JSON encoded string.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

.. _function-edgedb.query_jsonclient-statement-params-opts-1:

*function* ``EdgeDB.query_json!(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query_json!(client(), String.t(), list(), [query_option()]) :: result()

Execute the query on the client and return the results as JSON encoded string. If an error occurs while executing the query, it will be raised as
as an ``EdgeDB.Error`` exception.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

*function* ``EdgeDB.query_required_single(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query_required_single(client(), String.t(), list(), [query_option()]) ::
     {:ok, result()} | {:error, Exception.t()}

Execute the query on the client and return a singleton-returning result as a ``{:ok, result}`` tuple.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

.. _function-edgedb.query_required_singleclient-statement-params-opts-1:

*function* ``EdgeDB.query_required_single!(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query_required_single!(client(), String.t(), list(), [query_option()]) :: result()

Execute the query on the client and return a singleton-returning result. If an error occurs while executing the query, it will be raised as an
``EdgeDB.Error`` exception.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

*function* ``EdgeDB.query_required_single_json(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query_required_single_json(client(), String.t(), list(), [query_option()]) ::
     {:ok, result()} | {:error, Exception.t()}

Execute the query on the client and return a singleton-returning result as a ``{:ok, json}`` tuple.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

.. _function-edgedb.query_required_single_jsonclient-statement-params-opts-1:

*function* ``EdgeDB.query_required_single_json!(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query_required_single_json!(client(), String.t(), list(), [query_option()]) :: result()

Execute the query on the client and return a singleton-returning result as JSON string. If an error occurs while executing the query, it will be
raised as an ``EdgeDB.Error`` exception.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

*function* ``EdgeDB.query_single(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query_single(client(), String.t(), list(), [query_option()]) ::
     {:ok, result()} | {:error, Exception.t()}

Execute the query on the client and return an optional singleton-returning result as a ``{:ok, result}`` tuple.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

.. _function-edgedb.query_singleclient-statement-params-opts-1:

*function* ``EdgeDB.query_single!(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query_single!(client(), String.t(), list(), [query_option()]) :: result()

Execute the query on the client and return an optional singleton-returning result. If an error occurs while executing the query, it will be
raised as an ``EdgeDB.Error`` exception.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

*function* ``EdgeDB.query_single_json(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query_single_json(client(), String.t(), list(), [query_option()]) ::
     {:ok, result()} | {:error, Exception.t()}

Execute the query on the client and return an optional singleton-returning result as a ``{:ok, json}`` tuple.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

.. _function-edgedb.query_single_jsonclient-statement-params-opts-1:

*function* ``EdgeDB.query_single_json!(client, statement, params \\ [], opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.query_single_json!(client(), String.t(), list(), [query_option()]) :: result()

Execute the query on the client and return an optional singleton-returning result as JSON encoded string. If an error occurs while executing the
query, it will be raised as an ``EdgeDB.Error`` exception.

For the general usage, see ``EdgeDB.query/4``.

See ``EdgeDB.query_option/0`` for supported options.

*function* ``EdgeDB.rollback(client, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.rollback(EdgeDB.Client.t(), [rollback_option()]) :: no_return()

Rollback an open transaction.

See ``EdgeDB.rollback_option/0`` for supported options.

.. code:: iex

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> {:error, :tx_rollback} =
   ...(2)>  EdgeDB.transaction(client, fn tx_conn ->
   ...(2)>   EdgeDB.rollback(tx_conn, reason: :tx_rollback)
   ...(2)>  end)

*function* ``EdgeDB.start_link(opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.start_link(String.t()) :: GenServer.on_start()
   @spec EdgeDB.start_link([start_option()]) :: GenServer.on_start()

Creates a pool of EdgeDB connections linked to the current process.

If the first argument is a string, it will be assumed to be the DSN or instance name and passed as ``[dsn: dsn]`` keyword list to connect.

.. code:: iex

   iex(1)> {:ok, _client} = EdgeDB.start_link("edgedb://edgedb:edgedb@localhost:5656/edgedb")

Otherwise, if the first argument is a list, it will be used as is to connect. See ``EdgeDB.start_option/0`` for supported connection options.

.. code:: iex

   iex(1)> {:ok, _client} = EdgeDB.start_link(instance: "edgedb_elixir")

*function* ``EdgeDB.start_link(dsn, opts)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.start_link(String.t(), [start_option()]) :: GenServer.on_start()

Creates a pool of EdgeDB connections linked to the current process.

The first argument is the string which will be assumed as the DSN and passed as ``[dsn: dsn]`` keyword list along with other options to connect.
See ``EdgeDB.start_option/0`` for supported connection options.

.. code:: iex

   iex(1)> {:ok, _client} = EdgeDB.start_link("edgedb://edgedb:edgedb@localhost:5656/edgedb", tls_security: :insecure)

*function* ``EdgeDB.transaction(client, callback, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.transaction(client(), (EdgeDB.Client.t() -> result()), [transaction_option()]) ::
     {:ok, result()} | {:error, term()}

Open a retryable transaction loop.

EdgeDB clients support transactions that are robust to network errors, server failure, and some transaction conflicts. For more information see
`RFC`_.

The result of the transaction is the ``{:ok, result}`` tuple, where ``result`` is the result of the ``callback`` function executed in the
transaction.

To rollback an open transaction, use ``EdgeDB.rollback/2``.

``EdgeDB.transaction/3`` calls **cannot** be nested more than once.

.. code:: iex

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> {:ok, tickets} = EdgeDB.transaction(client, fn client ->
   ...(2)>  EdgeDB.query!(client, "insert v1::Ticket{ number := 2}")
   ...(2)>  EdgeDB.query!(client, "select v1::Ticket")
   ...(2)> end)
   iex(3)> tickets
   #EdgeDB.Set<{#EdgeDB.Object<>}>

See ``EdgeDB.transaction_option/0`` for supported options.

*function* ``EdgeDB.with_client_state(client, state)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.with_client_state(client(), EdgeDB.Client.State.t()) :: client()

Returns client with adjusted state.

See ``EdgeDB.with_default_module/2``, ``EdgeDB.with_module_aliases/2``/``EdgeDB.without_module_aliases/2``,
``EdgeDB.with_config/2``/``EdgeDB.without_config/2``, ``EdgeDB.with_globals/2``/``EdgeDB.without_globals/2`` for more information.

*function* ``EdgeDB.with_config(client, config \\ %{})``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.with_config(client(), EdgeDB.Client.State.config()) :: client()

Returns client with adjusted session config.

This is equivalent to using the ``configure session set`` command.

*function* ``EdgeDB.with_default_module(client, module \\ nil)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.with_default_module(client(), String.t() | nil) :: client()

Returns client with adjusted default module.

This is equivalent to using the ``set module`` command, or using the ``reset module`` command when giving ``nil``.

*function* ``EdgeDB.with_globals(client, globals \\ %{})``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.with_globals(client(), %{required(String.t()) => String.t()}) :: client()

Returns client with adjusted global values.

This is equivalent to using the ``set global`` command.

*function* ``EdgeDB.with_module_aliases(client, aliases \\ %{})``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.with_module_aliases(client(), %{required(String.t()) => String.t()}) :: client()

Returns client with adjusted module aliases.

This is equivalent to using the ``set alias`` command.

*function* ``EdgeDB.with_retry_options(client, opts)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.with_retry_options(client(), [EdgeDB.Client.retry_option()]) :: client()

Configure the client so that futher transactions retries are executed with custom retries options.

See ``EdgeDB.Client.retry_option/0`` for supported options.

*function* ``EdgeDB.with_transaction_options(client, opts)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.with_transaction_options(client(), [EdgeDB.Client.transaction_option()]) :: client()

Configure the client so that futher transactions are executed with custom transaction options.

See ``EdgeDB.transaction_option/0`` for supported options.

*function* ``EdgeDB.without_config(client, config_keys \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.without_config(client(), [EdgeDB.Client.State.config_key()]) :: client()

Returns client without specified session config.

This is equivalent to using the ``configure session reset`` command.

*function* ``EdgeDB.without_globals(client, global_names \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.without_globals(client(), [String.t()]) :: client()

Returns client without specified globals.

This is equivalent to using the ``reset global`` command.

*function* ``EdgeDB.without_module_aliases(client, aliases \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.without_module_aliases(client(), [String.t()]) :: client()

Returns client without specified module aliases.

This is equivalent to using the ``reset alias`` command.

EdgeDB.Client
-------------

Сlient is a structure that stores a custom configuration to execute EdgeQL queries and has a reference to a connection or pool of connections.

After starting the pool via ``EdgeDB.start_link/1`` or siblings, the client instance for the pool will be implicitly registered.

In case you want to change the behavior of your queries, you will use the ``EdgeDB.Client``, which is acceptable by all ``EdgeDB`` API and will
be provided to you in a callback in the ``EdgeDB.transaction/3`` function.

.. _edgedb-elixir-api-types-1:

Types
~~~~~

*type* ``EdgeDB.Client.retry_option/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Client.retry_option() :: {:transaction_conflict, retry_rule()} | {:network_error, retry_rule()}

Options for transactions and read-only queries retries.

See ``EdgeDB.transaction/3``.

Supported options:

-  ``:transaction_conflict`` - the rule that will be used in case of any transaction conflict.
-  ``:network_error`` - rule which will be used when any network error occurs on the client.

*type* ``EdgeDB.Client.retry_rule/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Client.retry_rule() :: {:attempts, pos_integer()} | {:backoff, (pos_integer() -> timeout())}

Options for a retry rule for transactions retries.

See ``EdgeDB.transaction/3``.

Supported options:

-  ``:attempts`` - the number of attempts to retry the transaction in case of an error.
-  ``:backoff`` - function to determine the backoff before the next attempt to run a transaction.

*type* ``EdgeDB.Client.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Client.t() :: %EdgeDB.Client{
     conn: DBConnection.conn(),
     readonly: boolean(),
     retry_options: [retry_option()],
     state: EdgeDB.Client.State.t(),
     transaction_options: [transaction_option()]
   }

Client is structure with stored configuration for executing EdgeQL queries and reference to pool or connection.

Fields:

-  ``:conn`` - reference to connection or pool of connections.
-  ``:readonly`` - flag specifying that the client is read-only.
-  ``:transaction_options`` - options for EdgeDB transactions.
-  ``:retry_options`` - options for a retry rule for transactions retries.
-  ``:state`` - execution context that affects the execution of EdgeQL commands.

*type* ``EdgeDB.Client.transaction_option/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Client.transaction_option() ::
     {:isolation, :serializable} | {:readonly, boolean()} | {:deferrable, boolean()}

Options for EdgeDB transactions.

These options are responsible for building the appropriate EdgeQL statement to start transactions and they correspond to `the EdgeQL transaction
statement`_.

Supported options:

-  ``:isolation`` - If ``:serializable`` is used, the built statement will use the ``isolation serializable`` mode. Currently only
   ``:serializable`` is supported by this client and EdgeDB.
-  ``:readonly`` - if set to ``true`` then the built statement will use ``read only`` mode, otherwise ``read write`` will be used. The default is
   ``false``.
-  ``:deferrable`` - if set to ``true`` then the built statement will use ``deferrable`` mode, otherwise ``not deferrable`` will be used. The
   default is ``false``.

EdgeDB.Client.State
-------------------

State for the client is an execution context that affects the execution of EdgeQL commands in different ways:

1. default module.
2. module aliases.
3. session config.
4. global values.

The most convenient way to work with the state is to use the ``EdgeDB`` API to change a required part of the state.

See ``EdgeDB.with_client_state/2``, ``EdgeDB.with_default_module/2``, ``EdgeDB.with_module_aliases/2``/``EdgeDB.without_module_aliases/2``,
``EdgeDB.with_config/2``/``EdgeDB.without_config/2`` and ``EdgeDB.with_globals/2``/``EdgeDB.without_globals/2`` for more information.

.. _edgedb-elixir-api-types-2:

Types
~~~~~

*type* ``EdgeDB.Client.State.config/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Client.State.config() :: %{required(config_key()) => term()} | [{config_key(), term()}]

Config to be passed to ``EdgeDB.with_config/2``.

*type* ``EdgeDB.Client.State.config_key/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Client.State.config_key() ::
     :allow_user_specified_id
     | :session_idle_timeout
     | :session_idle_transaction_timeout
     | :query_execution_timeout

Keys that EdgeDB accepts for changing client behaviour configuration.

The meaning and acceptable values can be found in the `docs`_.

*type* ``EdgeDB.Client.State.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @opaque EdgeDB.Client.State.t()

State for the client is an execution context that affects the execution of EdgeQL commands.

.. _edgedb-elixir-api-functions-1:

Functions
~~~~~~~~~

*function* ``EdgeDB.Client.State.with_config(state, config \\ %{})``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Client.State.with_config(t(), config()) :: t()

Returns an ``EdgeDB.Client.State`` with adjusted session config.

This is equivalent to using the ``configure session set`` command.

*function* ``EdgeDB.Client.State.with_default_module(state, module \\ nil)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Client.State.with_default_module(t(), String.t() | nil) :: t()

Returns an ``EdgeDB.Client.State`` with adjusted default module.

This is equivalent to using the ``set module`` command, or using the ``reset module`` command when giving ``nil``.

*function* ``EdgeDB.Client.State.with_globals(state, globals \\ %{})``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Client.State.with_globals(t(), %{required(String.t()) => String.t()}) :: t()

Returns an ``EdgeDB.Client.State`` with adjusted global values.

This is equivalent to using the ``set global`` command.

*function* ``EdgeDB.Client.State.with_module_aliases(state, aliases \\ %{})``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Client.State.with_module_aliases(t(), %{required(String.t()) => String.t()}) :: t()

Returns an ``EdgeDB.Client.State`` with adjusted module aliases.

This is equivalent to using the ``set alias`` command.

*function* ``EdgeDB.Client.State.without_config(state, config_keys \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Client.State.without_config(t(), [config_key()]) :: t()

Returns an ``EdgeDB.Client.State`` without specified session config.

This is equivalent to using the ``configure session reset`` command.

*function* ``EdgeDB.Client.State.without_globals(state, global_names \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Client.State.without_globals(t(), [String.t()]) :: t()

Returns an ``EdgeDB.Client.State`` without specified globals.

This is equivalent to using the ``reset global`` command.

*function* ``EdgeDB.Client.State.without_module_aliases(state, aliases \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Client.State.without_module_aliases(t(), [String.t()]) :: t()

Returns an ``EdgeDB.Client.State`` without specified module aliases.

This is equivalent to using the ``reset alias`` command.

EdgeDB.Sandbox
--------------

Custom connection for tests that involve modifying the database through the driver.

This connection, when started, wraps the actual connection to EdgeDB into a transaction using the ``start transaction`` statement. And then
further calls to ``EdgeDB.transaction/3`` will result in executing ``declare savepoint`` statement instead of ``start transaction``.

To use this module in tests, change the configuration of the ``:edgedb`` application in the ``config/test.exs``:

.. code:: elixir

   config :edgedb,
     connection: EdgeDB.Sandbox

Then modify the test case to initialize the sandbox when you run the test and to clean the sandbox at the end of the test:

.. code:: elixir

   defmodule MyApp.TestCase do
     use ExUnit.CaseTemplate

     # other stuff for this case (e.g. Phoenix setup, Plug configuration, etc.)

     setup _context do
       EdgeDB.Sandbox.initialize(MyApp.EdgeDB)

       on_exit(fn ->
         EdgeDB.Sandbox.clean(MyApp.EdgeDB)
       end)

       :ok
     end
   end

.. _edgedb-elixir-api-functions-2:

Functions
~~~~~~~~~

*function* ``EdgeDB.Sandbox.clean(client)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Sandbox.clean(GenServer.server()) :: :ok

Release the connection transaction.

*function* ``EdgeDB.Sandbox.initialize(client)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Sandbox.initialize(GenServer.server()) :: :ok

Wrap a connection in a transaction.

.. _the EdgeDB documentation on connection parameters: https://www.edgedb.com/docs/reference/connection#ref-reference-connection-granular
.. _the EdgeQL transaction statement: https://www.edgedb.com/docs/reference/edgeql/tx_start#statement::start-transaction
.. _RFC: https://github.com/edgedb/rfcs/blob/master/text/1004-transactions-api.rst
.. _docs: https://www.edgedb.com/docs/stdlib/cfg#client-connections
