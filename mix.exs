defmodule EdgeDB.MixProject do
  use Mix.Project

  @app :edgedb
  @version "0.2.0"
  @source_url "https://github.com/nsidnev/edgedb-elixir"
  @description "EdgeDB driver for Elixir"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.12",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      test_coverage: test_coverage(),
      preferred_cli_env: preferred_cli_env(),
      dialyzer: dialyzer(),
      aliases: aliases(),
      name: "EdgeDB",
      description: @description,
      docs: docs(),
      package: package()
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
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_env) do
    ["lib"]
  end

  defp elixirc_options do
    [
      warnings_as_errors: true
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit],
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp test_coverage do
    [
      tool: ExCoveralls
    ]
  end

  defp preferred_cli_env do
    [
      dialyzer: :test,
      credo: :test,
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.github": :test,
      "coveralls.html": :test
    ]
  end

  defp package do
    [
      maintainers: ["Nik Sidnev"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      source_url: @source_url,
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
