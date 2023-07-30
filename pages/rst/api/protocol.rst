.. _edgedb-elixir-api-protocol:

API/Protocol
============

EdgeDB.Protocol.Codec
---------------------

A codec knows how to work with the internal binary data from EdgeDB. The binary protocol specification for the codecs can be found in `the
relevant part of the EdgeDB documentation`_. Useful links for codec developers:

-  `EdgeDB datatypes used in data descriptions`_.
-  `EdgeDB data wire formats`_.
-  `Built-in EdgeDB codec implementations`_.
-  `Custom codecs implementations`_.
-  Guide to developing custom codecs on `hex.pm`_ or on `edgedb.com`_.

Types
~~~~~

*type* ``EdgeDB.Protocol.Codec.id/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Protocol.Codec.id() :: bitstring()

Codec ID.

*type* ``EdgeDB.Protocol.Codec.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Protocol.Codec.t() :: term()

All the types that implement this protocol.

Functions
~~~~~~~~~

*function* ``EdgeDB.Protocol.Codec.decode(codec, data, codec_storage)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Protocol.Codec.decode(t(), bitstring(), EdgeDB.Protocol.CodecStorage.t()) :: value when value: term()

Function that can decode EdgeDB binary format into an entity.

*function* ``EdgeDB.Protocol.Codec.encode(codec, value, codec_storage)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Protocol.Codec.encode(t(), value, EdgeDB.Protocol.CodecStorage.t()) :: iodata() when value: term()

Function that can encode an entity to EdgeDB binary format.

EdgeDB.Protocol.CustomCodec
---------------------------

Behaviour for custom scalar codecs.

See custom codecs development guide on `hex.pm`_ or on `edgedb.com`_ for more information.

EdgeDB.Protocol.CodecStorage
----------------------------

A storage for each codec that the connection knows how to decode.

.. _edgedb-elixir-protocol-types-1:

Types
~~~~~

*type* ``EdgeDB.Protocol.CodecStorage.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Protocol.CodecStorage.t() :: :ets.tab()

A storage for each codec that the connection knows how to decode.

.. _edgedb-elixir-protocol-functions-1:

Functions
~~~~~~~~~

*function* ``EdgeDB.Protocol.CodecStorage.get(storage, id)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Protocol.CodecStorage.get(t(), binary()) :: EdgeDB.Protocol.Codec.t() | nil

Find a codec in the storage by ID.

*function* ``EdgeDB.Protocol.CodecStorage.get_by_name(storage, name)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Protocol.CodecStorage.get_by_name(t(), binary()) :: EdgeDB.Protocol.Codec.t() | nil

Find a codec in the storage by type name.

EdgeDB.Protocol.Enums
---------------------

Definition for enumerations used in EdgeDB protocol.

.. _edgedb-elixir-protocol-types-2:

Types
~~~~~

*type* ``EdgeDB.Protocol.Enums.capabilities/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Protocol.Enums.capabilities() :: [capability()]

Query capabilities.

*type* ``EdgeDB.Protocol.Enums.capability/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Protocol.Enums.capability() ::
     :readonly
     | :modifications
     | :session_config
     | :transaction
     | :ddl
     | :persistent_config
     | :all
     | :execute
     | :legacy_execute

Query capabilities.

Values:

-  ``:readonly`` - query is read-only.
-  ``:modifications`` - query is not read-only.
-  ``:session_config`` - query contains session config change.
-  ``:transaction`` - query contains start/commit/rollback of transaction or savepoint manipulation.
-  ``:ddl`` - query contains DDL.
-  ``:persistent_config`` - server or database config change.
-  ``:all`` - all possible capabilities.
-  ``:execute`` - capabilities to execute query.

*type* ``EdgeDB.Protocol.Enums.cardinality/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Protocol.Enums.cardinality() :: :no_result | :at_most_one | :one | :many | :at_least_one

Cardinality of the query result.

Values:

-  ``:no_result`` - query doesn’t return anything.
-  ``:at_most_one`` - query return an optional single elements.
-  ``:one`` - query return a single element.
-  ``:many`` - query return a set of elements.
-  ``:at_least_one`` - query return a set with at least of one elements.

*type* ``EdgeDB.Protocol.Enums.compilation_flag/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Protocol.Enums.compilation_flag() ::
     :inject_output_type_ids | :inject_output_type_names | :inject_output_object_ids

Compilation flags for query to extend it’s features.

Values:

-  ``:inject_output_type_ids`` - inject ``__tid__`` property as ``.__type__.id`` alias into returned objects.
-  ``:inject_output_type_names`` - inject ``__tname__`` property as ``.__type__.name`` alias into returned objects.
-  ``:inject_output_object_ids`` - inject ``id`` property into returned objects.

*type* ``EdgeDB.Protocol.Enums.compilation_flags/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Protocol.Enums.compilation_flags() :: [compilation_flag()]

Compilation flags for query to extend it’s features.

*type* ``EdgeDB.Protocol.Enums.output_format/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Protocol.Enums.output_format() :: :binary | :json | :json_elements | :none

Data output format.

Values:

-  ``:binary`` - return data encoded in binary.
-  ``:json`` - return data as single row and single field that contains the result set as a single JSON array.
-  ``:json_elements`` - return a single JSON string per top-level set element. This can be used to iterate over a large result set efficiently.
-  ``:none`` - prevent EdgeDB from returning anything event if EdgeQL query does it.

.. _the relevant part of the EdgeDB documentation: https://www.edgedb.com/docs/reference/protocol
.. _EdgeDB datatypes used in data descriptions: https://www.edgedb.com/docs/reference/protocol/index#conventions-and-data-types
.. _EdgeDB data wire formats: https://www.edgedb.com/docs/reference/protocol/dataformats
.. _Built-in EdgeDB codec implementations: https://github.com/edgedb/edgedb-elixir/tree/master/lib/edgedb/protocol/codecs
.. _Custom codecs implementations: https://github.com/edgedb/edgedb-elixir/tree/master/test/edgedb/protocol/codecs/custom
.. _hex.pm: https://hexdocs.pm/edgedb/custom-codecs.html
.. _edgedb.com: https://www.edgedb.com/docs/clients/elixir/custom-codecs
