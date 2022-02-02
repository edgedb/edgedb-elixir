defmodule EdgeDB.MixProject do
  use Mix.Project

  @version "0.0.0"

  def project do
    [
      app: :edgedb,
      version: @version,
      elixir: "~> 1.10",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [
        warnings_as_errors: true
      ],
      consolidate_protocols: Mix.env() != :test,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        dialyzer: :test,
        credo: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_add_apps: [:ex_unit],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      aliases: aliases(),
      name: "EdgeDB",
      description: "EdgeDB driver for Elixir",
      docs: docs()
    ]
  end

  def application do
    [
      mod: {EdgeDB.Application, []},
      extra_applications: [
        :crypto,
        :logger,
        :ssl
      ]
    ]
  end

  defp deps do
    [
      # core
      {:db_connection, "~> 2.0"},
      {:elixir_uuid, "~> 1.2"},
      {:decimal, "~> 2.0"},
      {:jason, "~> 1.2", optional: true},
      # dev/test
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/nsidnev/edgedb-elixir",
      source_ref: "v#{@version}",
      main: "main",
      extras: [
        "pages/main.md",
        "pages/usage.md",
        "pages/datatypes.md",
        "pages/custom-codecs.md",
        "CHANGELOG.md"
      ],
      groups_for_modules: [
        "EdgeDB types": [
          EdgeDB.Object,
          EdgeDB.Set,
          EdgeDB.NamedTuple,
          EdgeDB.RelativeDuration,
          EdgeDB.ConfigMemory
        ],
        Protocol: [
          EdgeDB.Protocol.Codec,
          EdgeDB.Protocol.Enums.Cardinality,
          EdgeDB.Protocol.Enums.Capabilities,
          EdgeDB.Protocol.Enums.IOFormat
        ]
      ]
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_env) do
    ["lib"]
  end

  defp aliases do
    [
      "edgedb.roles.setup": [
        "cmd priv/scripts/setup-roles.sh"
      ],
      "edgedb.roles.reset": [
        "cmd priv/scripts/drop-roles.sh",
        "cmd priv/scripts/setup-roles.sh"
      ]
    ]
  end
end
