.. _edgedb-elixir-api-edgedb-types:

API/EdgeDB types
================

EdgeDB.Object
-------------

An immutable representation of an object instance returned from a query.

``EdgeDB.Object`` implements ``Access`` behavior to access properties by key.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> %EdgeDB.Object{} = object =
   iex(2)>  EdgeDB.query_required_single!(client, """
   ...(2)>   select schema::ObjectType{
   ...(2)>     name
   ...(2)>   }
   ...(2)>   filter .name = 'std::Object'
   ...(2)>   limit 1
   ...(2)>  """)
   #EdgeDB.Object<name := "std::Object">
   iex(3)> object[:name]
   "std::Object"
   iex(4)> object["name"]
   "std::Object"

Links and links properties
~~~~~~~~~~~~~~~~~~~~~~~~~~

In EdgeDB, objects can have links to other objects or a set of objects. You can use the same syntax to access links values as for object
properties. Links can also have their own properties (denoted as ``@<link_prop_name>`` in EdgeQL syntax). You can use the same property name as
in the query to access them from the links.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> %EdgeDB.Object{} = object =
   iex(2)>  EdgeDB.query_required_single!(client, """
   ...(2)>   select schema::Property {
   ...(2)>       name,
   ...(2)>       annotations: {
   ...(2)>         name,
   ...(2)>         @value
   ...(2)>       }
   ...(2)>   }
   ...(2)>   filter .name = 'listen_port' and .source.name = 'cfg::Config'
   ...(2)>   limit 1
   ...(2)>  """)
   #EdgeDB.Object<name := "listen_port", annotations := #EdgeDB.Set<{#EdgeDB.Object<name := "cfg::system", @value := "true">}>>
   iex(3)> annotations = object[:annotations]
   #EdgeDB.Set<{#EdgeDB.Object<name := "cfg::system", @value := "true">}>
   iex(4)> link = Enum.at(annotations, 0)
   #EdgeDB.Object<name := "cfg::system", @value := "true">
   iex(5)> link["@value"]
   "true"

Types
~~~~~

*type* ``EdgeDB.Object.fields_option/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Object.fields_option() ::
     {:properties, boolean()}
     | {:links, boolean()}
     | {:link_properties, boolean()}
     | {:id, boolean()}
     | {:implicit, boolean()}

Options for ``EdgeDB.Object.fields/2``

Supported options:

-  ``:properties`` - flag to include object properties in returning list. The default is ``true``.
-  ``:links`` - flag to include object links in returning list. The default is ``true``.
-  ``:link_properies`` - flag to include object link properties in returning list. The default is ``true``.
-  ``:id`` - flag to include implicit ``:id`` in returning list. The default is ``false``.
-  ``:implicit`` - flag to include implicit fields (like ``:id`` or ``:__tid__``) in returning list. The default is ``false``.

*type* ``EdgeDB.Object.object/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @opaque EdgeDB.Object.object()

An immutable representation of an object instance returned from a query.

*type* ``EdgeDB.Object.properties_option/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Object.properties_option() :: {:id, boolean()} | {:implicit, boolean()}

Options for ``EdgeDB.Object.properties/2``

Supported options:

-  ``:id`` - flag to include implicit ``:id`` in returning list. The default is ``false``.
-  ``:implicit`` - flag to include implicit properties (like ``:id`` or ``:__tid__``) in returning list. The default is ``false``.

*type* ``EdgeDB.Object.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Object.t() :: %EdgeDB.Object{id: uuid() | nil}

An immutable representation of an object instance returned from a query.

Fields:

-  ``:id`` - a unique ID of the object instance in the database.

*type* ``EdgeDB.Object.uuid/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Object.uuid() :: String.t()

UUID value.

Functions
~~~~~~~~~

*function* ``EdgeDB.Object.fields(object, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Object.fields(object(), [fields_option()]) :: [String.t()]

Get object fields names (properties, links and link propries) as list of strings.

See ``EdgeDB.Object.fields_option/0`` for supported options.

*function* ``EdgeDB.Object.link_properties(object)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Object.link_properties(object()) :: [String.t()]

Get object link propeties names as list.

*function* ``EdgeDB.Object.links(object)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Object.links(object()) :: [String.t()]

Get object links names as list.

*function* ``EdgeDB.Object.properties(object, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Object.properties(object(), [properties_option()]) :: [String.t()]

Get object properties names as list.

See ``EdgeDB.Object.properties_option/0`` for supported options.

*function* ``EdgeDB.Object.to_map(object)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Object.to_map(object()) :: %{required(String.t()) => term()}

Convert an object into a regular map.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> object =
   iex(2)>  EdgeDB.query_required_single!(client, """
   ...(2)>   select schema::Property {
   ...(2)>       name,
   ...(2)>       annotations: {
   ...(2)>         name,
   ...(2)>         @value
   ...(2)>       }
   ...(2)>   }
   ...(2)>   filter .name = 'listen_port' and .source.name = 'cfg::Config'
   ...(2)>   limit 1
   ...(2)>  """)
   iex(3)> EdgeDB.Object.to_map(object)
   %{"name" => "listen_port", "annotations" => [%{"name" => "cfg::system", "@value" => "true"}]}

EdgeDB.Set
----------

A representation of an immutable set of values returned by a query. Nested sets in the result are also returned as ``EdgeDB.Set`` objects.

``EdgeDB.Set`` implements ``Enumerable`` protocol for iterating over set values.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> %EdgeDB.Set{} =
   iex(2)>  EdgeDB.query!(client, """
   ...(2)>   select schema::ObjectType{
   ...(2)>     name
   ...(2)>   }
   ...(2)>   filter .name IN {'std::BaseObject', 'std::Object', 'std::FreeObject'}
   ...(2)>   order by .name
   ...(2)>  """)
   #EdgeDB.Set<{#EdgeDB.Object<name := "std::BaseObject">, #EdgeDB.Object<name := "std::FreeObject">, #EdgeDB.Object<name := "std::Object">}>

.. _edgedb-elixir-edgedb-types-types-1:

Types
~~~~~

*type* ``EdgeDB.Set.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @opaque EdgeDB.Set.t()

A representation of an immutable set of values returned by a query.

.. _edgedb-elixir-edgedb-types-functions-1:

Functions
~~~~~~~~~

*function* ``EdgeDB.Set.empty?(set)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Set.empty?(t()) :: boolean()

Check if set is empty.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> %EdgeDB.Set{} = set = EdgeDB.query!(client, "select Ticket")
   iex(3)> EdgeDB.Set.empty?(set)
   true

EdgeDB.NamedTuple
-----------------

An immutable value representing an EdgeDB named tuple value.

``EdgeDB.NamedTuple`` implements ``Access`` behavior to access fields by index or key and ``Enumerable`` protocol for iterating over tuple
values.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> nt = EdgeDB.query_required_single!(client, "select (a := 1, b := 'a', c := [3])")
   #EdgeDB.NamedTuple<a: 1, b: "a", c: [3]>
   iex(3)> nt[:b]
   "a"
   iex(4)> nt["c"]
   [3]
   iex(4)> nt[0]
   1

.. _edgedb-elixir-edgedb-types-types-2:

Types
~~~~~

*type* ``EdgeDB.NamedTuple.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @opaque EdgeDB.NamedTuple.t()

An immutable value representing an EdgeDB named tuple value.

.. _edgedb-elixir-edgedb-types-functions-2:

Functions
~~~~~~~~~

*function* ``EdgeDB.NamedTuple.keys(named_tuple)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.NamedTuple.keys(t()) :: [String.t()]

Get named tuple keys.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> nt = EdgeDB.query_required_single!(client, "select (a := 1, b := 'a', c := [3])")
   iex(3)> EdgeDB.NamedTuple.keys(nt)
   ["a", "b", "c"]

*function* ``EdgeDB.NamedTuple.to_map(named_tuple)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.NamedTuple.to_map(t()) :: %{required(String.t()) => term()}

Convert a named tuple into a regular map.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> nt = EdgeDB.query_required_single!(client, "select (a := 1, b := 'a', c := [3])")
   iex(3)> EdgeDB.NamedTuple.to_map(nt)
   %{"a" => 1, "b" => "a", "c" => [3]}

*function* ``EdgeDB.NamedTuple.to_tuple(nt)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.NamedTuple.to_tuple(t()) :: tuple()

Convert a named tuple to a regular erlang tuple.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> nt = EdgeDB.query_required_single!(client, "select (a := 1, b := 'a', c := [3])")
   iex(3)> EdgeDB.NamedTuple.to_tuple(nt)
   {1, "a", [3]}

EdgeDB.RelativeDuration
-----------------------

An immutable value represeting an EdgeDB ``cal::relative_duration`` value.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> EdgeDB.query_required_single!(client, "select <cal::relative_duration>'45.6 seconds'")
   #EdgeDB.RelativeDuration<"PT45.6S">

.. _edgedb-elixir-edgedb-types-types-3:

Types
~~~~~

*type* ``EdgeDB.RelativeDuration.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.RelativeDuration.t() :: %EdgeDB.RelativeDuration{
     days: pos_integer(),
     microseconds: pos_integer(),
     months: pos_integer()
   }

An immutable value represeting an EdgeDB ``cal::relative_duration`` value.

Fields:

-  ``:months`` - number of months.
-  ``:days`` - number of days.
-  ``:microseconds`` - number of microseconds.

EdgeDB.DateDuration
-------------------

An immutable value represeting an EdgeDB ``cal::date_duration`` value.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> EdgeDB.query_required_single!(client, "select <cal::date_duration>'1 year 2 days'")
   #EdgeDB.DateDuration<"P1Y2D">

.. _edgedb-elixir-edgedb-types-types-4:

Types
~~~~~

*type* ``EdgeDB.DateDuration.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.DateDuration.t() :: %EdgeDB.DateDuration{days: integer(), months: integer()}

An immutable value represeting an EdgeDB ``cal::date_duration`` value.

Fields:

-  ``:days`` - number of days.
-  ``:months`` - number of months.

EdgeDB.ConfigMemory
-------------------

An immutable value represeting an EdgeDB ``cfg::memory`` value as a quantity of memory storage.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> mem = EdgeDB.query_required_single!(client, "select <cfg::memory>'5KiB'")
   #EdgeDB.ConfigMemory<"5KiB">
   iex(3)> EdgeDB.ConfigMemory.bytes(mem)
   5120

.. _edgedb-elixir-edgedb-types-types-5:

Types
~~~~~

*type* ``EdgeDB.ConfigMemory.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @opaque EdgeDB.ConfigMemory.t()

An immutable value represeting an EdgeDB ``cfg::memory`` value as a quantity of memory storage.

.. _edgedb-elixir-edgedb-types-functions-3:

Functions
~~~~~~~~~

*function* ``EdgeDB.ConfigMemory.bytes(config_memory)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.ConfigMemory.bytes(t()) :: pos_integer()

Get a quantity of memory storage in bytes.

EdgeDB.Range
------------

A value representing some interval of values.

.. code:: elixir

   iex(1)> {:ok, client} = EdgeDB.start_link()
   iex(2)> EdgeDB.query_required_single!(client, "select range(1, 10)")
   #EdgeDB.Range<[1, 10)>

.. _edgedb-elixir-edgedb-types-types-6:

Types
~~~~~

*type* ``EdgeDB.Range.creation_option/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Range.creation_option() :: {:inc_lower, boolean()} | {:inc_upper, boolean()} | {:empty, boolean()}

Options for ``EdgeDB.Range.new/3`` function.

Supported options:

-  ``:inc_lower`` - flag whether the created range should strictly include the lower boundary.
-  ``:inc_upper`` - flag whether the created range should strictly include the upper boundary.
-  ``:empty`` - flag to create an empty range.

*type* ``EdgeDB.Range.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Range.t() :: t(value())

A value of ``EdgeDB.Range.value/0`` type representing some interval of values.

*type* ``EdgeDB.Range.t/1``
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Range.t(value) :: %EdgeDB.Range{
     inc_lower: boolean(),
     inc_upper: boolean(),
     is_empty: boolean(),
     lower: value | nil,
     upper: value | nil
   }

A value of ``EdgeDB.Range.value/0`` type representing some interval of values.

Fields:

-  ``:lower`` - data for the lower range boundary.
-  ``:upper`` - data for the upper range boundary.
-  ``:inc_lower`` - flag whether the range should strictly include the lower boundary.
-  ``:inc_upper`` - flag whether the range should strictly include the upper boundary.
-  ``:is_empty`` - flag for an empty range.

*type* ``EdgeDB.Range.value/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Range.value() :: integer() | float() | Decimal.t() | DateTime.t() | NaiveDateTime.t() | Date.t()

A type that is acceptable by EdgeDB ranges.

.. _edgedb-elixir-edgedb-types-functions-4:

Functions
~~~~~~~~~

*function* ``EdgeDB.Range.empty()``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Range.empty() :: t()

Create an empty range.

.. code:: elixir

   iex(1)> EdgeDB.Range.empty()
   #EdgeDB.Range<empty>

*function* ``EdgeDB.Range.new(lower, upper, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Range.new(value | nil, value | nil, [creation_option()]) :: t(value) when value: value()

Create new range.

.. code:: elixir

   iex(1)> EdgeDB.Range.new(1.1, 3.3, inc_upper: true)
   #EdgeDB.Range<[1.1, 3.3]>
