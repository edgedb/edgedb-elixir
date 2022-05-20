
# Datatypes
EdgeDB driver for Elixir automatically converts EdgeDB types to the corresponding Elixir types and vice versa.

The table below shows the correspondence between EdgeDB and Elixir types.

| EdgeDB                    | Elixir                                   | Example                                              |
| ------------------------- | ---------------------------------------- | ---------------------------------------------------- |
| `str`                     | `t:String.t/0`                           | `"Hello EdgeDB!"`                                    |
| `bool`                    | `t:boolean/0`                            | `true`, `false`                                      |
| `int16`, `int32`, `int64` | `t:integer/0`                            | `16`                                                 |
| `float32`, `float64`      | `t:float/0`                              | `3.1415`                                             |
| `bigint`, `decimal`       | `t:Decimal.t/0`                          | `#Decimal<1.23>`                                     |
| `json`                    | `t:any/0`                                | `42`                                                 |
| `uuid`                    | `t:String.t/0`                           | `"0eba1636-846e-11ec-845e-276b0105b857"`             |
| `anyenum`                 | `t:String.t/0`                           | `"green"`                                            |
| `datetime`                | `t:DateTime.t/0`                         | `~U[2018-05-07 15:01:22Z]`                           |
| `duration`                | `t:integer/0` or `Timex.Duration`        | `-420000000`, `#<Duration(PT7M)>`                    |
| `cal::local_datetime`     | `t:NaiveDateTime.t/0`                    | `~N[2018-05-07 15:01:22]`                            |
| `cal::local_date`         | `t:Date.t/0`                             | `~D[2018-05-07]`                                     |
| `cal::local_time`         | `t:Time.t/0`                             | `~T[15:01:22]`                                       |
| `cal::relative_duration`  | `t:EdgeDB.RelativeDuration.t/0`          | `#EdgeDB.RelativeDuration<"PT45.6S">`                |
| `bytes`                   | `t:binary/0`                             | `<<1, 2, 3>>`, `"some bytes"`                        |
| `array<anytype>`          | `t:list/0`                               | `[1, 2, 3]`                                          |
| `anytuple`                | `t:tuple/0` or `t:EdgeDB.NamedTuple.t/0` | `{1, 2, 3}`, `#EdgeDB.NamedTuple<a: 1, b: 2, c: 3>}` |
| `object`                  | `t:EdgeDB.Object.t/0`                    | `#EdgeDB.Object<name := "username">}`                |
| `set`                     | `t:EdgeDB.Set.t/0`                       | `#EdgeDB.Set<{1, 2, 3}>}`                            |
| `cfg::memory`             | `t:EdgeDB.ConfigMemory.t/0`              | `#EdgeDB.ConfigMemory<"5KiB">`                       |
