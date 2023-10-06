.. _edgedb-elixir-intro:

EdgeDB client for Elixir
========================

.. toctree::
  :maxdepth: 3
  :hidden:

  usage
  codegen
  datatypes
  custom-codecs
  api/api
  api/edgedb-types
  api/protocol
  api/errors



``edgedb-elixir`` is the `EdgeDB`_ client for Elixir. The documentation for client is available on `edgedb.com`_ and on `hex.pm`_.

Installation
------------

``edgedb-elixir`` is available on `hex.pm <https://hex.pm/packages/edgedb>`__ and can be installed via ``mix``. Just add ``:edgedb`` to your
dependencies in the ``mix.exs`` file:

.. code:: elixir

   {:edgedb, "~> 0.1"}

JSON support
------------

``EdgeDB`` comes with JSON support out of the box via the ``Jason`` library.

The JSON library can be configured using the ``:json`` option in the ``:edgedb`` application configuration:

.. code:: elixir

   config :edgedb,
       json: CustomJSONLibrary

The JSON library is injected in the compiled ``EdgeDB`` code, so be sure to recompile ``EdgeDB`` if you change it:

.. code:: bash

   $ mix deps.clean edgedb --build

Timex support
-------------

``EdgeDB`` can work with ``Timex`` out of the box. If you define ``Timex`` as an application dependency, ``EdgeDB`` will use ``Timex.Duration``
to encode and decode the ``std::duration`` type from database. If you don’t like this behavior, you can set ``EdgeDB`` to ignore ``Timex`` using
the ``:timex_duration`` option by setting this to false in the ``:edgedb`` application configuration:

.. code:: elixir

   config :edgedb,
       timex_duration: false

``EdgeDB`` will inject the use of ``Timex`` into the ``std::duration`` codec at compile time, so be sure to recompile ``EdgeDB`` if you change
this behavior:

.. code:: bash

   $ mix deps.clean edgedb --build

License
-------

This project is licensed under the terms of the Apache 2.0 license. See `LICENSE`_ for details.

.. _EdgeDB: https://edgedb.com
.. _edgedb.com: https://www.edgedb.com/docs/clients/elixir
.. _hex.pm: https://hexdocs.pm/edgedb
.. _LICENSE: https://github.com/edgedb/edgedb-elixir/blob/master/LICENSE
