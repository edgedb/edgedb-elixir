defmodule EdgeDB.MixProject do
  use Mix.Project

  @app :edgedb
  @version "0.6.1"
  @source_url "https://github.com/edgedb/edgedb-elixir"
  @description "EdgeDB client for Elixir"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.12",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: consolidate_protocols?(Mix.env()),
      test_coverage: test_coverage(),
      preferred_cli_env: preferred_cli_env(),
      dialyzer: dialyzer(),
      name: "EdgeDB",
      description: @description,
      package: package(),
      docs: docs(),
      aliases: aliases()
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
      {:jose, "~> 1.11"},
      {:crc, "~> 0.10.4"},
      {:castore, "~> 0.1.0 or ~> 1.0"},
      {:jason, "~> 1.2", optional: true},
      {:timex, "~> 3.7", optional: true},
      # dev/test
      {:dialyxir, "~> 1.0", only: [:dev, :ci], runtime: false},
      {:credo, "~> 1.2", only: [:dev, :ci], runtime: false},
      {:ex_doc, "~> 0.28", only: [:dev, :ci], runtime: false},
      {:excoveralls, "~> 0.14", only: [:test, :ci]},
      {:mox, "~> 1.0", only: [:test, :ci]}
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

  defp consolidate_protocols?(:test) do
    false
  end

  defp consolidate_protocols?(_env) do
    true
  end

  defp test_coverage do
    [
      tool: ExCoveralls
    ]
  end

  defp preferred_cli_env do
    [
      dialyzer: :ci,
      credo: :ci,
      docs: :ci,
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.html": :test
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [
        :ex_unit,
        :jason,
        :timex
      ],
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp package do
    [
      maintainers: [
        "Nik Sidnev"
      ],
      licenses: ["Apache-2.0"],
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
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_modules: [
        "EdgeDB types": [
          EdgeDB.Object,
          EdgeDB.Set,
          EdgeDB.NamedTuple,
          EdgeDB.RelativeDuration,
          EdgeDB.DateDuration,
          EdgeDB.ConfigMemory,
          EdgeDB.Range
        ],
        Protocol: [
          EdgeDB.Protocol.Codec,
          EdgeDB.Protocol.CustomCodec,
          EdgeDB.Protocol.CodecStorage,
          EdgeDB.Protocol.Enums
        ],
        Errors: edgedb_errors(Mix.env())
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

  # this may take some time, so make sure we only do it when necessary
  defp edgedb_errors(:ci) do
    error_regex = ~r/^0x(_[0-9A-Fa-f]{2}){4}\s*(?<error_name>\w+)/

    for line <- File.stream!("./priv/edgedb/api/errors.txt"), Regex.match?(error_regex, line) do
      %{"error_name" => error_name} = Regex.named_captures(error_regex, line)
      Module.concat([EdgeDB, error_name])
    end
  end

  defp edgedb_errors(_env) do
    []
  end
end
