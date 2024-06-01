import Config

import_config("#{Mix.env()}.exs")

config :edgedb,
  generation: [
    queries_path: "test/support/codegen/edgeql/",
    output_path: "test/codegen/queries/",
    module_prefix: Tests.Codegen.Queries,
    atomize_enums: true
  ]
