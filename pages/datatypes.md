
# Datatypes
EdgeDB driver for Elixir automatically converts EdgeDB types to the corresponding Elixir types and vice versa.

The table below shows the correspondence between EdgeDB and Elixir types.

| EdgeDB                              | Elixir                                   | Example                                               |
| ----------------------------------- | ---------------------------------------- | ----------------------------------------------------- |
| `set`                               | `t:EdgeDB.Set.t/0`                       | `#EdgeDB.Set<{1, 2, 3}>}`                             |
| `array<anytype>`                    | `t:list/0`                               | `[1, 2, 3]`                                           |
| `anytuple`                          | `t:tuple/0` or `t:EdgeDB.NamedTuple.t/0` | `{1, 2, 3}`, ` #EdgeDB.NamedTuple<a: 1, b: 2, c: 3>}` |
| `anyenum`                           | `t:String.t/0`                           | `"green"`                                             |
| `Object`                            | `t:EdgeDB.Object.t/0`                    | `#EdgeDB.Object<name := "username">}`                 |
| `bool`                              | `t:boolean/0`                            | `true`, `false`                                       |
| `bytes`                             | `t:binary/0`                             | `<<1, 2, 3>>`, `"some bytes"`                         |
| `str`                               | `t:String.t/0`                           | `"Hello EdgeDB!"`                                     |
| `cal::local_date`                   | `t:Date.t/0`                             | `~D[2018-05-07]`                                      |
| `cal::local_time`                   | `t:Time.t/0`                             | `~T[15:01:22]`                                        |
| `cal::local_datetime`               | `t:NaiveDateTime.t/0`                    | `~N[2018-05-07 15:01:22]`                             |
| `cal::relative_duration`            | `t:EdgeDB.RelativeDuration.t/0`          | `#EdgeDB.RelativeDuration<"PT45.6S">`                 |
| `datetime`                          | `t:DateTime.t/0`                         | `~U[2018-05-07 15:01:22Z]`                            |
| `duration`                          | `t:integer/0`                            | `-420000000`                                          |
| `float32`, `float64`                | `t:float/0`                              | `3.1415`                                              |
| `int16`, `int32`, `int64`, `bigint` | `t:integer/0`                            | `16`                                                  |
| `decimal`                           | `t:Decimal.t/0`                          | `#Decimal<1.23>`                                      |
| `json`                              | `t:any/0`                                | `42`                                                  |
| `uuid`                              | `t:String.t/0`                           | `"0eba1636-846e-11ec-845e-276b0105b857"`              |
