edgedb_version = System.get_env("EDGEDB_VERSION")

excludes =
  case edgedb_version do
    "1" ->
      [edgedb_v2: true]

    _other ->
      []
  end

ExUnit.start(capture_log: true, exclude: excludes)
