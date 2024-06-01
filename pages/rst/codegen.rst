.. _edgedb-elixir-codegen:

Code Generation with Elixir client
==================================

``edgedb-elixir`` provides a custom ``Mix`` task for generating Elixir modules from EdgeQL query files.

First, add the following lines for ``:edgedb`` to the config:

.. code:: elixir

   config :edgedb, :generation,
     queries_path: "priv/edgedb/edgeql/",
     output_path: "lib/my_app/edgedb/queries",
     module_prefix: MyApp.EdgeDB

Or in case you have multiple locations for your queries like this:

.. code:: elixir

   config :edgedb,
     generation: [
       [
         queries_path: "priv/edgedb/edgeql/path1",
         output_path: "lib/my_app/edgedb/queries/path1",
         module_prefix: MyApp.EdgeDB.Path1
       ],
       [
         queries_path: "priv/edgedb/edgeql/path2",
         output_path: "lib/my_app/edgedb/queries/path2",
         module_prefix: MyApp.EdgeDB.Path2
       ],
     ]

..

.. note::
      :name: note-.info

   ``module_prefix`` is an optional parameter that allows you to control the prefix for the module being generated

Then, let’s place a new EdgeQL query into ``priv/edgedb/edgeql/select_string.edgeql``:

.. code:: edgeql

   select <optional str>$arg

Now we can run ``mix edgedb.generate`` and it should produce new ``lib/my_app/edgedb/queries/select_string.edgeql.ex``. The result should look
similar to this:

.. code:: elixir

   defmodule MyApp.EdgeDB.SelectString do
     @query """
     select <optional str>$arg
     """

     @type keyword_args() :: [{:arg, String.t() | nil}]
     @type map_args() :: %{arg: String.t() | nil}
     @type args() :: map_args() | keyword_args()

     @spec query(client :: EdgeDB.client(), args :: args(), opts :: list(EdgeDB.query_option())) ::
             {:ok, String.t() | nil} | {:error, reason} when reason: any()
     def query(client, args, opts \\ []) do
       do_query(client, args, opts)
     end

     @spec query!(client :: EdgeDB.client(), args :: args(), opts :: list(EdgeDB.query_option())) ::
             String.t() | nil
     def query!(client, args, opts \\ []) do
       case do_query(client, args, opts) do
         {:ok, result} ->
           result

         {:error, exc} ->
           raise exc
       end
     end

     defp do_query(client, args, opts) do
       EdgeDB.query_single(client, @query, args, opts)
     end
   end

To use it just call the ``MyApp.EdgeDB.SelectString.query/3`` function:

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> {:ok, "hello world"} = MyApp.EdgeDB.SelectString.query(client, arg: "hello world")

You can check out a more interesting and complete use case in the example repository: https://github.com/nsidnev/edgebeats
