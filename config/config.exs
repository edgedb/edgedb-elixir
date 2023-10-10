import Config

import_config("#{Mix.env()}.exs")

config :edgedb,
  generation: [
    queries_path: "test/support/codegen/edgeql/",
    output_path: "test/codegen/queries/",
    module_prefix: Tests.Codegen.Queries
  ]

# TODO: clean edgedb/edgeql, edgedb/schema, edgedb.toml
# config :edgedb,
#   generation: [
#     queries_path: "priv/edgedb/edgeql/",
#     output_path: "priv/edgedb/codegen/queries/",
#     module_prefix: Tests.Codegen.Queries
#   ]
