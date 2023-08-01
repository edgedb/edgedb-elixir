.. _edgedb-elixir-datatypes:

Datatypes
=========

EdgeDB client for Elixir automatically converts EdgeDB types to the corresponding Elixir types and vice versa.

The table below shows the correspondence between EdgeDB and Elixir types.

============================================== ======================================== ========================================================
EdgeDB                                         Elixir                                   Example
============================================== ======================================== ========================================================
``std::str``                                   ``String.t/0``                           ``"Hello EdgeDB!"``
``std::int16``, ``std::int32``, ``std::int64`` ``integer/0``                            ``16``
``std::float32``, ``std::float64``             ``float/0``                              ``3.1415``
``std::bigint``, ``std::decimal``              ``Decimal.t/0``                          ``#Decimal<1.23>``
``std::bool``                                  ``boolean/0``                            ``true``, ``false``
``std::datetime``                              ``DateTime.t/0``                         ``~U[2018-05-07 15:01:22Z]``
``std::duration``                              ``integer/0`` or ``Timex.Duration``      ``-420000000``, ``#<Duration(PT7M)>``
``cal::local_datetime``                        ``NaiveDateTime.t/0``                    ``~N[2018-05-07 15:01:22]``
``cal::local_date``                            ``Date.t/0``                             ``~D[2018-05-07]``
``cal::local_time``                            ``Time.t/0``                             ``~T[15:01:22]``
``cal::relative_duration``                     ``EdgeDB.RelativeDuration.t/0``          ``#EdgeDB.RelativeDuration<"PT45.6S">``
``cal::date_duration``                         ``EdgeDB.DateDuration.t/0``              ``#EdgeDB.DateDuration<"P4Y12D">``
``std::json``                                  ``any/0``                                ``42``
``std::uuid``                                  ``String.t/0``                           ``"0eba1636-846e-11ec-845e-276b0105b857"``
``std::bytes``                                 ``binary/0``                             ``<<1, 2, 3>>``, ``"some bytes"``
``cfg::memory``                                ``EdgeDB.ConfigMemory.t/0``              ``#EdgeDB.ConfigMemory<"5KiB">``
``ext::pgvector::vector``                      ``list/0``                               ``[1.5, 2.0, 4.5]``
``anyenum``                                    ``String.t/0``                           ``"green"``
``array<anytype>``                             ``list/0``                               ``[1, 2, 3]``
``anytuple``                                   ``tuple/0`` or ``EdgeDB.NamedTuple.t/0`` ``{1, 2, 3}``, ``#EdgeDB.NamedTuple<a: 1, b: 2, c: 3>}``
``range``                                      ``EdgeDB.Range.t/0``                     ``#EdgeDB.Range<[1.1, 3.3)>``
``object``                                     ``EdgeDB.Object.t/0``                    ``#EdgeDB.Object<name := "username">}``
``set``                                        ``EdgeDB.Set.t/0``                       ``#EdgeDB.Set<{1, 2, 3}>}``
============================================== ======================================== ========================================================
